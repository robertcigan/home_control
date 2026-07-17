import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.boundHandleClick = this.handleClick.bind(this)
    this.element.addEventListener("click", this.boundHandleClick)
  }

  disconnect() {
    this.element.removeEventListener("click", this.boundHandleClick)
  }

  handleClick(event) {
    event.preventDefault()

    const link = event.currentTarget
    const method = (link.dataset.turboMethod || link.dataset.method || "get").toUpperCase()
    const csrfToken = document.querySelector("meta[name='csrf-token']")
    const headers = {
      Accept: "text/html, application/xhtml+xml",
      "X-Requested-With": "XMLHttpRequest"
    }

    if (csrfToken) {
      headers["X-CSRF-Token"] = csrfToken.content
    }

    const options = {
      method: method,
      headers: headers,
      credentials: "same-origin"
    }

    if (method !== "GET" && method !== "HEAD") {
      const formData = new FormData()
      formData.append("_method", method.toLowerCase())

      if (csrfToken) {
        formData.append("authenticity_token", csrfToken.content)
      }

      options.method = "POST"
      options.body = formData
    }

    fetch(link.href, options)
  }
}
