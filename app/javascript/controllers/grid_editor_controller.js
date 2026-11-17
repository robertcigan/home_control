import { Controller } from "@hotwired/stimulus"
import { GridStack } from "gridstack"

export default class extends Controller {
  static values = {
    column: Number,
    row: Number
  }

  connect() {
    this.boundHandleWidgetUpdate = this.handleWidgetUpdate.bind(this)
    this.boundUpdateCellHeight = this.updateCellHeight.bind(this)
    this.element.addEventListener("widget:update", this.boundHandleWidgetUpdate, true)

    this.grid = GridStack.init({
      float: true,
      alwaysShowResizeHandle: "mobile",
      column: this.columnValue,
      row: this.rowValue,
      cellHeight: this.cellHeightPx()
    }, this.element)

    this.grid.on("change", (_event, items) => {
      items.forEach((item) => {
        const el = item.el

        if (item.x !== undefined) {
          el.setAttribute("gs-x", item.x)
        }

        if (item.y !== undefined) {
          el.setAttribute("gs-y", item.y)
        }

        if (item.w !== undefined) {
          el.setAttribute("gs-w", item.w)
        }

        if (item.h !== undefined) {
          el.setAttribute("gs-h", item.h)
        }

        el.dispatchEvent(new CustomEvent("widget:update", { bubbles: true }))
      })
    })

    window.addEventListener("resize", this.boundUpdateCellHeight)
    this.scheduleFontResize()
  }

  disconnect() {
    this.element.removeEventListener("widget:update", this.boundHandleWidgetUpdate, true)
    window.removeEventListener("resize", this.boundUpdateCellHeight)

    if (this.fontResizeFrame) {
      cancelAnimationFrame(this.fontResizeFrame)
      this.fontResizeFrame = null
    }

    if (this.grid) {
      this.grid.destroy(false)
      this.grid = null
    }
  }

  updateCellHeight() {
    if (this.grid) {
      this.grid.cellHeight(this.cellHeightPx())
      this.scheduleFontResize()
    }
  }

  // Fonts can only be fitted once GridStack has laid out the items,
  // so the resize runs on the next animation frame.
  scheduleFontResize() {
    if (this.fontResizeFrame) {
      cancelAnimationFrame(this.fontResizeFrame)
    }

    this.fontResizeFrame = requestAnimationFrame(() => {
      this.fontResizeFrame = null
      this.element.dispatchEvent(new CustomEvent("widget:resize", { bubbles: true }))
    })
  }

  // Stretch the grid from its top edge down to the bottom of the viewport
  // (minus the page's bottom padding), never below its CSS min-height.
  // GridStack sets an inline height on the element, so it can't be measured directly.
  cellHeightPx() {
    const top = this.element.getBoundingClientRect().top + window.scrollY
    const bottomGap = parseFloat(getComputedStyle(document.body).paddingBottom) || 0
    const minHeight = parseFloat(getComputedStyle(this.element).minHeight) || 0
    const height = Math.max(minHeight, window.innerHeight - top - bottomGap)

    return Math.max(1, Math.floor(height / this.rowValue))
  }

  handleWidgetUpdate(event) {
    const item = event.target.closest(".grid-stack-item") || event.target

    if (!item || !item.classList.contains("grid-stack-item")) {
      return
    }

    this.syncInputs(item)
    this.persistPosition(item)
    item.dispatchEvent(new CustomEvent("widget:resize", { bubbles: true }))
  }

  syncInputs(item) {
    const xInput = item.querySelector("input[data-gs='x']")
    const yInput = item.querySelector("input[data-gs='y']")
    const wInput = item.querySelector("input[data-gs='w']")
    const hInput = item.querySelector("input[data-gs='h']")

    if (xInput) {
      xInput.value = item.getAttribute("gs-x")
    }

    if (yInput) {
      yInput.value = item.getAttribute("gs-y")
    }

    if (wInput) {
      wInput.value = item.getAttribute("gs-w")
    }

    if (hInput) {
      hInput.value = item.getAttribute("gs-h")
    }
  }

  persistPosition(item) {
    const form = item.querySelector("form")

    if (!form) {
      return
    }

    const csrfToken = document.querySelector("meta[name='csrf-token']")
    const headers = {
      Accept: "text/vnd.turbo-stream.html, text/html, application/xhtml+xml"
    }

    if (csrfToken) {
      headers["X-CSRF-Token"] = csrfToken.content
    }

    const formData = new FormData(form)

    fetch(form.action, {
      method: "POST",
      headers: headers,
      body: formData,
      credentials: "same-origin"
    })
  }
}
