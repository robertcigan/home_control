import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.boundHandleInput = this.handleInput.bind(this)
    this.element.querySelectorAll(".search-field").forEach((field) => {
      field.addEventListener("input", this.boundHandleInput)
    })
  }

  disconnect() {
    this.element.querySelectorAll(".search-field").forEach((field) => {
      field.removeEventListener("input", this.boundHandleInput)
    })

    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  handleInput(event) {
    const field = event.target
    const delay = parseInt(field.dataset.debounceTime || "1000", 10)

    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    this.timeout = setTimeout(() => {
      const form = field.closest("form")

      if (form) {
        form.requestSubmit()
      }
    }, delay)
  }
}
