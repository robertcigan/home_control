import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

// Explicit opt-in via data-controller="select" — no global auto-init.
export default class extends Controller {
  connect() {
    if (this.element.tomselect) {
      return
    }

    const plugins = {}
    const allowClear = this.element.dataset.allowClear !== "false"
    const isMultiple = this.element.multiple

    if (allowClear && !isMultiple) {
      plugins.clear_button = {
        title: "Clear",
        html: (config) => {
          return `<div class="${config.className}" title="${config.title}">&times;</div>`
        }
      }
    }

    if (isMultiple) {
      plugins.remove_button = { title: "Remove" }
    }

    this.suppressChange = true

    const options = {
      plugins: plugins,
      allowEmptyOption: true,
      maxOptions: null,
      onChange: () => {
        this.syncClearButton()

        if (this.suppressChange) {
          return
        }

        this.element.dispatchEvent(new Event("change", { bubbles: true }))
      }
    }

    if (this.element.dataset.placeholder) {
      options.placeholder = this.element.dataset.placeholder
    }

    this.select = new TomSelect(this.element, options)
    this.syncClearButton()

    requestAnimationFrame(() => {
      this.suppressChange = false
    })
  }

  disconnect() {
    this.select?.destroy()
  }

  syncClearButton() {
    if (!this.select) {
      return
    }

    const value = this.select.getValue()
    let hasSelection = false

    if (Array.isArray(value)) {
      if (value.some((item) => item !== "")) {
        hasSelection = true
      }
    } else if (value !== "" && value != null) {
      hasSelection = true
    }

    this.select.wrapper.classList.toggle("has-selection", hasSelection)
  }
}
