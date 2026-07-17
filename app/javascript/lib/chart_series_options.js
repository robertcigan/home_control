export function seriesOptions(type, name, data, color = null) {
  const points = (data || []).map((pair) => [new Date(pair[0]).getTime(), pair[1]])
  const options = {
    type: "line",
    showSymbol: false,
    data: points
  }

  if (name) {
    options.name = name
  }

  if (type === "step-area") {
    options.step = "end"
    if (color) {
      options.areaStyle = { color: color, opacity: 0.35 }
    } else {
      options.areaStyle = {}
    }
  } else if (type === "area") {
    if (color) {
      options.areaStyle = { color: color, opacity: 0.35 }
    } else {
      options.areaStyle = {}
    }
  } else if (type === "points") {
    // Keep series type "line" so dataZoom / slider / mini-graph stay unchanged;
    // hide the stroke and show markers only (legacy Chart.js showLine: false).
    options.showSymbol = true
    options.symbolSize = 8
    options.lineStyle = { width: 0, opacity: 0 }
  }

  if (color) {
    options.color = color
    if (type === "points") {
      options.itemStyle = { color: color }
    } else {
      options.lineStyle = { ...(options.lineStyle || {}), color: color }
    }
  }

  return options
}
