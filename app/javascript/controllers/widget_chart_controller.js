import { Controller } from "@hotwired/stimulus"
import * as echarts from "echarts"
import { seriesOptions } from "lib/chart_series_options"

const MAX_POINTS = 2000

export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    url: String,
    hours: Number,
    type: String
  }

  connect() {
    this.chart = echarts.init(this.canvasTarget)
    this.points = []
    this.pendingUpdate = null
    this.loading = true
    this.abortController = new AbortController()
    // The value from page render is already in the fetched logs (their timestamps
    // have only second precision), so only a later change adds a point.
    this.lastDeviceTs = Number(this.element.dataset.deviceTs) || 0

    this.resizeObserver = new ResizeObserver(() => {
      if (this.chart) {
        this.chart.resize()
      }
    })
    this.resizeObserver.observe(this.element)

    this.fetchSeries()
  }

  disconnect() {
    if (this.abortController) {
      this.abortController.abort()
      this.abortController = null
    }

    if (this.resizeObserver) {
      this.resizeObserver.disconnect()
      this.resizeObserver = null
    }

    if (this.chart) {
      this.chart.dispose()
      this.chart = null
    }
  }

  // Every device push (a value change or the periodic push of an unchanged device)
  // moves the time window to "now"; a point is added only when the value changed.
  deviceUpdate(event) {
    if (this.loading) {
      this.pendingUpdate = event
    } else {
      this.appendPointFromDataset()
      this.prune()
      this.render()
    }
  }

  async fetchSeries() {
    try {
      const response = await fetch(this.urlValue, { signal: this.abortController.signal })
      if (!response.ok) {
        this.loading = false
      } else {
        const data = await response.json()
        this.points = (data || []).map((pair) => [new Date(pair[0]).getTime(), pair[1]])
        this.loading = false
        if (this.pendingUpdate) {
          this.pendingUpdate = null
          this.appendPointFromDataset()
        }
        this.prune()
        this.render()
      }
    } catch (error) {
      if (error.name !== "AbortError") {
        this.loading = false
      }
    }
  }

  appendPointFromDataset() {
    const rawTs = this.element.dataset.deviceTs
    const rawValue = this.element.dataset.deviceChartValue
    if (rawTs === undefined || rawTs === "" || rawValue === undefined || rawValue === "") {
      return
    }

    const ts = Number(rawTs)
    const value = Number(rawValue)
    if (Number.isNaN(ts) || Number.isNaN(value)) {
      return
    }

    if (ts <= this.lastDeviceTs) {
      return
    }
    this.lastDeviceTs = ts

    if (this.points.length > 0) {
      const lastTs = this.points[this.points.length - 1][0]
      if (ts <= lastTs) {
        return
      }
    }

    this.points.push([ts, value])
  }

  // The current value held up to the end of the window. It isn't stored in this.points,
  // so it moves with time and doesn't leave a stale point behind.
  currentValuePoint(max) {
    const rawValue = this.element.dataset.deviceChartValue
    if (rawValue === undefined || rawValue === "") {
      return null
    }

    const value = Number(rawValue)
    if (Number.isNaN(value)) {
      return null
    }

    if (this.points.length > 0 && this.points[this.points.length - 1][0] >= max) {
      return null
    }

    return [max, value]
  }

  prune() {
    const { min } = this.windowBounds()

    while (this.points.length > 1 && this.points[1][0] < min) {
      this.points.shift()
    }

    if (this.points.length > MAX_POINTS) {
      this.points = this.points.slice(this.points.length - MAX_POINTS)
    }
  }

  windowBounds() {
    const windowMs = this.hoursValue * 3600 * 1000
    const now = Date.now()
    let lastTs = now
    if (this.points.length > 0) {
      lastTs = this.points[this.points.length - 1][0]
    }
    const max = Math.max(now, lastTs)
    const min = max - windowMs
    return { min, max }
  }

  render() {
    const { min, max } = this.windowBounds()
    const lineColor = this.lineColor()
    const textColor = getComputedStyle(this.element).color
    const currentPoint = this.currentValuePoint(max)
    let seriesData = this.points
    if (currentPoint) {
      seriesData = [...this.points, currentPoint]
    }

    this.chart.setOption(
      {
        animation: false,
        grid: { left: 40, right: 10, top: 16, bottom: 24 },
        xAxis: {
          type: "time",
          min: min,
          max: max,
          axisLabel: { color: textColor },
          axisLine: { lineStyle: { color: textColor } },
          splitLine: { show: false }
        },
        yAxis: {
          type: "value",
          scale: true,
          axisLabel: { color: textColor },
          axisLine: { lineStyle: { color: textColor } },
          splitLine: { lineStyle: { color: textColor, opacity: 0.25 } }
        },
        series: [seriesOptions(this.typeValue, null, seriesData, lineColor)]
      },
      { notMerge: true }
    )

    this.element.dataset.chartPoints = String(this.points.length)
    this.element.dataset.chartMax = String(max)
  }

  lineColor() {
    const color = getComputedStyle(this.element).getPropertyValue("--chart-line-color").trim()
    if (color) {
      return color
    } else {
      return getComputedStyle(this.element).color
    }
  }
}
