import { Controller } from "@hotwired/stimulus"
import { GridStack } from "gridstack"

export default class extends Controller {
  static values = {
    column: Number,
    row: Number
  }

  connect() {
    this.boundUpdateCellHeight = this.updateCellHeight.bind(this)

    this.grid = GridStack.init({
      float: true,
      alwaysShowResizeHandle: "mobile",
      staticGrid: true,
      column: this.columnValue,
      row: this.rowValue,
      cellHeight: this.cellHeightPx()
    }, this.element)

    window.addEventListener("resize", this.boundUpdateCellHeight)
  }

  disconnect() {
    window.removeEventListener("resize", this.boundUpdateCellHeight)

    if (this.grid) {
      this.grid.destroy(false)
      this.grid = null
    }
  }

  updateCellHeight() {
    if (this.grid) {
      this.grid.cellHeight(this.cellHeightPx())
    }
  }

  cellHeightPx() {
    return Math.max(1, Math.floor(this.element.clientHeight / this.rowValue))
  }
}
