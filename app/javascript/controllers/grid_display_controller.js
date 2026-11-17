import { Controller } from "@hotwired/stimulus"
import { GridStack } from "gridstack"

export default class extends Controller {
  static values = {
    column: Number,
    row: Number
  }

  connect() {
    this.appliedCellHeight = this.cellHeightPx()

    this.grid = GridStack.init({
      float: true,
      animate: false,
      alwaysShowResizeHandle: "mobile",
      staticGrid: true,
      column: this.columnValue,
      row: this.rowValue,
      cellHeight: this.appliedCellHeight
    }, this.element)

    this.resizeObserver = new ResizeObserver(() => {
      this.updateCellHeight()
    })
    this.resizeObserver.observe(this.sizeElement())

    this.scheduleFontResize()
  }

  disconnect() {
    if (this.resizeObserver) {
      this.resizeObserver.disconnect()
      this.resizeObserver = null
    }

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
    if (!this.grid) {
      return
    }

    // Hidden or not yet laid out container – don't collapse cells to 1px
    if (this.sizeElement().clientHeight === 0) {
      return
    }

    const next = this.cellHeightPx()

    if (next === this.appliedCellHeight) {
      return
    }

    this.appliedCellHeight = next
    this.grid.cellHeight(next)
    this.scheduleFontResize()
  }

  scheduleFontResize() {
    if (this.fontResizeFrame) {
      cancelAnimationFrame(this.fontResizeFrame)
    }

    this.fontResizeFrame = requestAnimationFrame(() => {
      this.fontResizeFrame = null
      this.element.dispatchEvent(new CustomEvent("widget:resize", { bubbles: true }))
    })
  }

  // GridStack sets an inline height (rows * cellHeight) on the grid element itself,
  // so the available height has to be measured on its parent.
  sizeElement() {
    return this.element.parentElement || this.element
  }

  cellHeightPx() {
    const rows = this.rowValue

    if (!rows) {
      return 1
    }

    return Math.max(1, Math.floor(this.sizeElement().clientHeight / rows))
  }
}
