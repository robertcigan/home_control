import { Controller } from "@hotwired/stimulus"

// Handles data-autosubmit for checkboxes and selects.
// Tom Select onChange dispatches a native Event so this controller hears them.
export default class extends Controller {
  connect() {
    this.boundHandleChange = this.handleChange.bind(this)
    this.element.addEventListener("change", this.boundHandleChange)
  }

  disconnect() {
    this.element.removeEventListener("change", this.boundHandleChange)
  }

  handleChange(event) {
    const target = event.target

    if (!target.matches("[data-autosubmit]")) {
      return
    }

    this.element.requestSubmit()
  }
}
