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

  deviceUpdate(event) {
    if (this.loading) {
      this.pendingUpdate = event
    } else {
      this.appendPointFromDataset()
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
        this.render()
        this.loading = false
        if (this.pendingUpdate) {
          this.pendingUpdate = null
          this.appendPointFromDataset()
        }
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

    if (this.points.length > 0) {
      const lastTs = this.points[this.points.length - 1][0]
      if (ts <= lastTs) {
        return
      }
    }

    this.points.push([ts, value])
    this.prune()
    this.render()
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
        series: [seriesOptions(this.typeValue, null, this.points, lineColor)]
      },
      { notMerge: true }
    )

    this.element.dataset.chartPoints = String(this.points.length)
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
