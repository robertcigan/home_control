import { Controller } from "@hotwired/stimulus"

// Handles data-reload for all controls (checkboxes, native inputs, selects).
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

    if (!target.matches("[data-reload]")) {
      return
    }

    let reloadInput = this.element.querySelector("input[name=reload][type=hidden]")

    if (!reloadInput) {
      reloadInput = document.createElement("input")
      reloadInput.type = "hidden"
      reloadInput.name = "reload"
      this.element.appendChild(reloadInput)
    }

    reloadInput.value = "1"
    this.element.requestSubmit()
  }
}
