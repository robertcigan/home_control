function isTrue(value) {
  return value === "true" || value === true
}

function isFalse(value) {
  return value === "false" || value === false
}

function setText(el, selector, value) {
  const target = el.querySelector(selector)

  if (!target) {
    return
  }

  if (value) {
    target.textContent = value
  } else {
    target.textContent = ""
  }
}

function autoFontResize(container = document.body) {
  let root = container

  if (typeof container === "string") {
    root = document.querySelector(container)
  }

  if (!root) {
    return
  }

  root.querySelectorAll(".resizable-font-size").forEach((el) => {
    const parentContainer = el.parentElement

    if (!parentContainer) {
      return
    }

    let fontSize = parentContainer.clientHeight * 0.8
    const maxWidth = parentContainer.clientWidth * 0.6

    el.style.fontSize = `${fontSize}px`

    if (el.offsetWidth > maxWidth && el.offsetWidth > 0) {
      fontSize = fontSize * maxWidth / el.offsetWidth
    }

    if (fontSize > 50) {
      fontSize = (fontSize - 50) * 0.3 + 50
    }

    el.style.fontSize = `${fontSize}px`

    if (el.offsetHeight > parentContainer.clientHeight * 0.8 && el.offsetHeight > 0) {
      fontSize = fontSize * parentContainer.clientHeight * 0.8 / el.offsetHeight
    }

    el.style.fontSize = `${fontSize}px`
  })
}

function handleDeviceUpdate(event) {
  const device = event.target

  if (isTrue(device.dataset.deviceStatus)) {
    device.classList.remove("device-off")
    device.classList.add("device-on")
  } else if (isFalse(device.dataset.deviceStatus)) {
    device.classList.remove("device-on")
    device.classList.add("device-off")
  }

  setText(device, ".updated", device.dataset.deviceUpdated)
  setText(device, ".indication", device.dataset.deviceIndication)

  const gridItem = device.closest(".grid-stack-item")

  if (gridItem) {
    gridItem.dispatchEvent(new CustomEvent("widget:resize", { bubbles: true }))
  }
}

function handleBoardUpdate(event) {
  const board = event.target

  if (isTrue(board.dataset.boardStatus)) {
    board.classList.remove("board-off")
    board.classList.add("board-on")
  } else if (isFalse(board.dataset.boardStatus)) {
    board.classList.remove("board-on")
    board.classList.add("board-off")
  }

  setText(board, ".ssid", board.dataset.boardSsid)
  setText(board, ".signal-strength", board.dataset.boardSignalStrength)
}

function handleProgramUpdate(event) {
  const program = event.target

  if (isTrue(program.dataset.programEnabled)) {
    program.classList.remove("program-off")
    program.classList.add("program-on")
  } else if (isFalse(program.dataset.programEnabled)) {
    program.classList.remove("program-on")
    program.classList.add("program-off")
  }

  if (isTrue(program.dataset.programHasError)) {
    program.classList.add("program-error")
  } else if (isFalse(program.dataset.programHasError)) {
    program.classList.remove("program-error")
  }

  setText(program, ".runtime", program.dataset.programRuntime)
  setText(program, ".thread-utilisation", program.dataset.programThreadUtilisation)
  setText(program, ".last-run", program.dataset.programLastRun)
  setText(program, ".last-error-at", program.dataset.programLastErrorAt)
}

function dispatchInitialUpdates() {
  document.querySelectorAll(".device").forEach((el) => {
    el.dispatchEvent(new CustomEvent("device:update", { bubbles: true }))
  })

  document.querySelectorAll(".board").forEach((el) => {
    el.dispatchEvent(new CustomEvent("board:update", { bubbles: true }))
  })

  document.querySelectorAll(".program").forEach((el) => {
    el.dispatchEvent(new CustomEvent("program:update", { bubbles: true }))
  })

  autoFontResize()
}

function onReady() {
  dispatchInitialUpdates()
}

document.addEventListener("device:update", (event) => {
  if (event.target.matches(".device")) {
    handleDeviceUpdate(event)
  }
})

document.addEventListener("board:update", (event) => {
  if (event.target.matches(".board")) {
    handleBoardUpdate(event)
  }
})

document.addEventListener("program:update", (event) => {
  if (event.target.matches(".program")) {
    handleProgramUpdate(event)
  }
})

document.addEventListener("widget:resize", (event) => {
  autoFontResize(event.target)
})

document.addEventListener("mousedown", (event) => {
  const link = event.target.closest(".program a")

  if (!link) {
    return
  }

  const program = link.closest(".program")

  if (program) {
    program.classList.remove("program-stopped")
    program.classList.add("program-running")
  }
})

document.addEventListener("mouseup", (event) => {
  const link = event.target.closest(".program a")

  if (!link) {
    return
  }

  const program = link.closest(".program")

  if (program) {
    setTimeout(() => {
      program.classList.remove("program-running")
      program.classList.add("program-stopped")
    }, 300)
  }
})

window.addEventListener("resize", () => {
  autoFontResize()
})

document.addEventListener("turbo:load", onReady)
document.addEventListener("turbo:frame-load", onReady)

export { autoFontResize }
