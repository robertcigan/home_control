import { Controller } from "@hotwired/stimulus"
import * as echarts from "echarts"

export default class extends Controller {
  static targets = ["canvas", "label", "forward"]
  static values = {
    url: String,
    type: String,
    yTitle: String,
    timespan: String,
    multi: Boolean,
    min: String,
    max: String,
    now: String
  }

  connect() {
    this.chart = echarts.init(this.canvasTarget)
    this.abortController = null
    this.zoomTimer = null
    this.ignoreDataZoom = false
    this.loadGeneration = 0
    this.boundResize = this.handleResize.bind(this)
    this.boundDataZoom = this.handleDataZoom.bind(this)

    this.chart.on("datazoom", this.boundDataZoom)
    window.addEventListener("resize", this.boundResize)

    this.updateForwardButton()
    this.load({ resetView: true })
  }

  disconnect() {
    if (this.zoomTimer) {
      clearTimeout(this.zoomTimer)
      this.zoomTimer = null
    }

    if (this.allowZoomTimer) {
      clearTimeout(this.allowZoomTimer)
      this.allowZoomTimer = null
    }

    if (this.abortController) {
      this.abortController.abort()
      this.abortController = null
    }

    window.removeEventListener("resize", this.boundResize)

    if (this.chart) {
      this.chart.off("datazoom", this.boundDataZoom)
      this.chart.dispose()
      this.chart = null
    }
  }

  preset(event) {
    const timespan = event.params.timespan
    this.timespanValue = timespan

    const reference = this.hasNowValue ? new Date(this.nowValue) : new Date()
    const range = this.rangeForTimespan(timespan, reference)
    this.minValue = range.min.toISOString()
    this.maxValue = range.max.toISOString()
    this.updateActivePreset(timespan)
    this.updateLabel()
    this.updateForwardButton()
    this.load({ resetView: true })
  }

  shift(event) {
    const direction = Number(event.params.direction)
    const currentMin = new Date(this.minValue).getTime()
    const currentMax = new Date(this.maxValue).getTime()
    const span = currentMax - currentMin
    const amount = this.shiftAmount(this.timespanValue)

    let min = currentMin + (direction * amount)
    let max = currentMax + (direction * amount)

    const boundary = this.currentPeriodEnd()
    if (max > boundary) {
      max = boundary
      min = max - span
    }

    if (this.windowsClose(min, max, currentMin, currentMax)) {
      return
    }

    this.minValue = new Date(min).toISOString()
    this.maxValue = new Date(max).toISOString()
    this.updateLabel()
    this.updateForwardButton()
    this.load({ resetView: true })
  }

  handleDataZoom() {
    if (this.ignoreDataZoom) {
      return
    }

    if (this.zoomTimer) {
      clearTimeout(this.zoomTimer)
    }

    this.zoomTimer = setTimeout(() => {
      if (this.ignoreDataZoom || !this.chart) {
        return
      }

      const zoomWindow = this.readZoomWindow()
      if (!zoomWindow) {
        return
      }

      const currentMin = new Date(this.minValue).getTime()
      const currentMax = new Date(this.maxValue).getTime()
      if (this.windowsClose(zoomWindow.min, zoomWindow.max, currentMin, currentMax)) {
        return
      }

      this.minValue = new Date(zoomWindow.min).toISOString()
      this.maxValue = new Date(zoomWindow.max).toISOString()
      this.updateLabel()
      this.updateForwardButton()

      // Pan/zoom inside the loaded buffer must not reload — any series/axis
      // rewrite makes ECharts jump the viewport. Refetch only at the edge to
      // extend the buffer while preserving the visible window.
      const nearEdge = zoomWindow.startPercent < 8 || zoomWindow.endPercent > 92
      if (nearEdge) {
        this.load({ resetView: false, expandBuffer: true })
      }
    }, 350)
  }

  handleResize() {
    if (this.chart) {
      this.chart.resize()
    }
  }

  async load({ resetView = true, expandBuffer = false } = {}) {
    if (this.abortController) {
      this.abortController.abort()
    }

    this.abortController = new AbortController()
    this.loadGeneration += 1
    const generation = this.loadGeneration

    const visibleMin = new Date(this.minValue).getTime()
    const visibleMax = new Date(this.maxValue).getTime()
    const span = Math.max(visibleMax - visibleMin, 1)
    const fetchRange = this.fetchRangeForLoad(resetView || expandBuffer, visibleMin, visibleMax, span)

    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set("min", new Date(fetchRange.min).toISOString())
    url.searchParams.set("max", new Date(fetchRange.max).toISOString())
    url.searchParams.set("timespan", this.timespanValue)

    try {
      const response = await fetch(url.toString(), {
        headers: { Accept: "application/json" },
        credentials: "same-origin",
        signal: this.abortController.signal
      })

      if (!response.ok) {
        return
      }

      const payload = await response.json()
      if (generation !== this.loadGeneration || !this.chart) {
        return
      }

      if (resetView) {
        this.renderChart(payload)
      } else if (expandBuffer) {
        this.expandBuffer(payload, visibleMin, visibleMax, span)
      } else {
        this.updateSeries(payload, visibleMin, visibleMax)
      }
    } catch (error) {
      if (error.name !== "AbortError") {
        throw error
      }
    }
  }

  // Mini-graph on the slider covers the whole x-axis. Fetch that buffer so the
  // overview matches the selected window shown in the main chart.
  fetchRangeForLoad(useVisiblePadding, visibleMin, visibleMax, span) {
    if (!useVisiblePadding && this.chart) {
      const option = this.chart.getOption()
      const axis = option.xAxis && option.xAxis[0]
      if (axis) {
        const axisMin = Number(this.unwrapOptionValue(axis.min))
        const axisMax = Number(this.unwrapOptionValue(axis.max))
        if (!Number.isNaN(axisMin) && !Number.isNaN(axisMax) && axisMax > axisMin) {
          return { min: axisMin, max: axisMax }
        }
      }
    }

    return {
      min: visibleMin - span,
      max: visibleMax + span
    }
  }

  renderChart(payload) {
    const min = new Date(this.minValue).getTime()
    const max = new Date(this.maxValue).getTime()
    const span = Math.max(max - min, 1)
    // dataZoom 0–100 % je přes data extent. Bez paddingu je okno na 100 %
    // a slider/drag nemá kam posouvat — proto osa = 3× viditelné okno.
    // Vpravo je osa oříznutá koncem aktuálního období — do budoucnosti
    // nejde posouvat.
    const axisMin = min - span
    const axisMax = Math.max(Math.min(max + span, this.currentPeriodEnd()), max)
    const series = this.seriesWithAxisExtent(this.buildSeries(payload), axisMin, axisMax)

    this.ignoreDataZoom = true
    this.chart.setOption(
      {
        animation: false,
        tooltip: { trigger: "axis" },
        legend: this.multiValue ? { top: 0 } : undefined,
        grid: { left: 50, right: 20, top: this.multiValue ? 40 : 20, bottom: 84 },
        xAxis: {
          type: "time",
          min: axisMin,
          max: axisMax
        },
        yAxis: {
          type: "value",
          name: this.yTitleValue,
          scale: true
        },
        dataZoom: [
          {
            type: "inside",
            xAxisIndex: 0,
            filterMode: "none",
            rangeMode: ["value", "value"],
            startValue: min,
            endValue: max,
            zoomOnMouseWheel: true,
            moveOnMouseMove: true,
            moveOnMouseWheel: false
          },
          {
            type: "slider",
            xAxisIndex: 0,
            filterMode: "none",
            rangeMode: ["value", "value"],
            startValue: min,
            endValue: max,
            height: 40,
            bottom: 4,
            brushSelect: false,
            showDetail: false,
            showDataShadow: true,
            handleSize: 24,
            fillerColor: "rgba(13, 110, 253, 0.35)",
            borderColor: "#6c757d",
            borderWidth: 1,
            backgroundColor: "#ced4da",
            handleStyle: {
              color: "#0d6efd",
              borderColor: "#0a58ca",
              borderWidth: 1
            },
            moveHandleSize: 10,
            moveHandleStyle: {
              color: "#0d6efd"
            },
            dataBackground: {
              lineStyle: { color: "#495057", width: 1 },
              areaStyle: { color: "#adb5bd" }
            },
            selectedDataBackground: {
              lineStyle: { color: "#0a58ca", width: 1 },
              areaStyle: { color: "#9ec5fe" }
            },
            emphasis: {
              handleStyle: {
                color: "#0a58ca"
              }
            }
          }
        ],
        series: series
      },
      { notMerge: true }
    )
    this.scheduleAllowDataZoom()
  }

  // Shift the padded axis under the current window without jumping the viewport.
  expandBuffer(payload, visibleMin, visibleMax, span) {
    const axisMin = visibleMin - span
    const axisMax = Math.max(Math.min(visibleMax + span, this.currentPeriodEnd()), visibleMax)
    const series = this.seriesWithAxisExtent(this.buildSeries(payload), axisMin, axisMax)

    this.ignoreDataZoom = true
    this.chart.setOption({
      xAxis: {
        min: axisMin,
        max: axisMax
      },
      dataZoom: [
        {
          startValue: visibleMin,
          endValue: visibleMax
        },
        {
          startValue: visibleMin,
          endValue: visibleMax
        }
      ],
      series: series
    })
    this.scheduleAllowDataZoom()
  }

  updateSeries(payload, visibleMin, visibleMax) {
    this.ignoreDataZoom = true

    let axisMin = null
    let axisMax = null
    const option = this.chart.getOption()
    const axis = option.xAxis && option.xAxis[0]
    if (axis) {
      axisMin = Number(this.unwrapOptionValue(axis.min))
      axisMax = Number(this.unwrapOptionValue(axis.max))
    }

    let series = this.buildSeries(payload)
    if (!Number.isNaN(axisMin) && !Number.isNaN(axisMax) && axisMax > axisMin) {
      series = this.seriesWithAxisExtent(series, axisMin, axisMax)
    }

    const zoomMin = visibleMin === undefined ? new Date(this.minValue).getTime() : visibleMin
    const zoomMax = visibleMax === undefined ? new Date(this.maxValue).getTime() : visibleMax

    this.chart.setOption({
      series: series,
      dataZoom: [
        {
          startValue: zoomMin,
          endValue: zoomMax
        },
        {
          startValue: zoomMin,
          endValue: zoomMax
        }
      ]
    })
    this.scheduleAllowDataZoom()
  }

  // ECharts dataZoom extent follows series data, not xAxis min/max. Without
  // endpoints at the axis bounds, sparse data is stretched across the slider.
  seriesWithAxisExtent(series, axisMin, axisMax) {
    return series.map((entry) => {
      const data = entry.data || []
      return Object.assign({}, entry, {
        connectNulls: false,
        data: [[axisMin, null]].concat(data, [[axisMax, null]])
      })
    })
  }

  scheduleAllowDataZoom() {
    if (this.allowZoomTimer) {
      clearTimeout(this.allowZoomTimer)
    }

    // Keep ignoring long enough that setOption's own datazoom event is skipped.
    this.allowZoomTimer = setTimeout(() => {
      this.ignoreDataZoom = false
      this.allowZoomTimer = null
    }, 400)
  }

  readZoomWindow() {
    const option = this.chart.getOption()
    const dataZooms = option.dataZoom || []
    const dataZoom = dataZooms[1] || dataZooms[0]
    if (!dataZoom) {
      return null
    }

    const axis = option.xAxis && option.xAxis[0]
    const start = Number(this.unwrapOptionValue(dataZoom.start))
    const end = Number(this.unwrapOptionValue(dataZoom.end))
    const axisMin = axis ? Number(this.unwrapOptionValue(axis.min)) : NaN
    const axisMax = axis ? Number(this.unwrapOptionValue(axis.max)) : NaN

    // Prefer percent + axis extent — after drag, startValue can lag behind start/end.
    if (!Number.isNaN(start) && !Number.isNaN(end) && !Number.isNaN(axisMin) && !Number.isNaN(axisMax)) {
      const axisSpan = axisMax - axisMin
      return {
        min: axisMin + (axisSpan * start / 100),
        max: axisMin + (axisSpan * end / 100),
        startPercent: start,
        endPercent: end
      }
    }

    const startValue = Number(this.unwrapOptionValue(dataZoom.startValue))
    const endValue = Number(this.unwrapOptionValue(dataZoom.endValue))
    if (Number.isNaN(startValue) || Number.isNaN(endValue) || endValue <= startValue) {
      return null
    }

    return {
      min: startValue,
      max: endValue,
      startPercent: 50,
      endPercent: 50
    }
  }

  windowsClose(minA, maxA, minB, maxB) {
    return Math.abs(minA - minB) < 1000 && Math.abs(maxA - maxB) < 1000
  }

  unwrapOptionValue(value) {
    if (Array.isArray(value)) {
      return value[0]
    }

    return value
  }

  buildSeries(payload) {
    if (this.multiValue) {
      return payload.map((entry) => this.seriesOptions(entry.name, entry.data))
    }

    return [this.seriesOptions(null, payload)]
  }

  seriesOptions(name, data) {
    const points = (data || []).map((pair) => [new Date(pair[0]).getTime(), pair[1]])
    const options = {
      type: "line",
      showSymbol: false,
      data: points
    }

    if (name) {
      options.name = name
    }

    if (this.typeValue === "step-area") {
      options.step = "end"
      options.areaStyle = {}
    } else if (this.typeValue === "points") {
      // Keep series type "line" so dataZoom / slider / mini-graph stay unchanged;
      // hide the stroke and show markers only (legacy Chart.js showLine: false).
      options.showSymbol = true
      options.symbolSize = 8
      options.lineStyle = { width: 0, opacity: 0 }
    }

    return options
  }

  rangeForTimespan(timespan, reference) {
    const date = new Date(reference.getTime())

    if (timespan === "hour") {
      const min = new Date(date)
      min.setMinutes(0, 0, 0)
      const max = new Date(min.getTime())
      max.setMinutes(59, 59, 999)
      return { min, max }
    }

    if (timespan === "day") {
      const min = new Date(date)
      min.setHours(0, 0, 0, 0)
      const max = new Date(date)
      max.setHours(23, 59, 59, 999)
      return { min, max }
    }

    if (timespan === "week") {
      const min = new Date(date)
      min.setHours(0, 0, 0, 0)
      const day = min.getDay()
      const mondayOffset = day === 0 ? -6 : 1 - day
      min.setDate(min.getDate() + mondayOffset)
      const max = new Date(min.getTime())
      max.setDate(max.getDate() + 6)
      max.setHours(23, 59, 59, 999)
      return { min, max }
    }

    if (timespan === "month") {
      const min = new Date(date.getFullYear(), date.getMonth(), 1, 0, 0, 0, 0)
      const max = new Date(date.getFullYear(), date.getMonth() + 1, 0, 23, 59, 59, 999)
      return { min, max }
    }

    const min = new Date(date.getFullYear(), 0, 1, 0, 0, 0, 0)
    const max = new Date(date.getFullYear(), 11, 31, 23, 59, 59, 999)
    return { min, max }
  }

  // End of the period containing "now" — the hard right edge for shifting
  // and panning; the future holds no data.
  currentPeriodEnd() {
    return this.rangeForTimespan(this.timespanValue, new Date()).max.getTime()
  }

  shiftAmount(timespan) {
    if (timespan === "hour") {
      return 60 * 60 * 1000
    }

    if (timespan === "day") {
      return 24 * 60 * 60 * 1000
    }

    if (timespan === "week") {
      return 7 * 24 * 60 * 60 * 1000
    }

    if (timespan === "month") {
      return 30 * 24 * 60 * 60 * 1000
    }

    return 365 * 24 * 60 * 60 * 1000
  }

  updateActivePreset(timespan) {
    this.element.querySelectorAll("[data-action*='chart#preset']").forEach((button) => {
      if (button.dataset.chartTimespanParam === timespan) {
        button.classList.add("active")
      } else {
        button.classList.remove("active")
      }
    })
  }

  updateLabel() {
    if (!this.hasLabelTarget) {
      return
    }

    this.labelTarget.textContent = this.formatLabel(new Date(this.minValue), this.timespanValue)
  }

  updateForwardButton() {
    if (!this.hasForwardTarget) {
      return
    }

    const max = new Date(this.maxValue).getTime()
    this.forwardTarget.disabled = max >= this.currentPeriodEnd() - 1000
  }

  formatLabel(date, timespan) {
    const day = date.getDate()
    const month = date.getMonth() + 1
    const year = date.getFullYear()
    const hour = date.getHours()

    if (timespan === "hour") {
      return `${day}.${month}.${year} ${hour}h`
    }

    if (timespan === "month") {
      return `${year}-${month}`
    }

    if (timespan === "year") {
      return `${year}`
    }

    return `${day}.${month}.${year}`
  }
}
