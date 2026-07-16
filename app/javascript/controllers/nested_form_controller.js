import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template"]

  add(event) {
    event.preventDefault()

    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime().toString())
    this.templateTarget.insertAdjacentHTML("beforebegin", content)
  }

  remove(event) {
    event.preventDefault()

    const wrapper = event.target.closest(".nested-fields")

    if (!wrapper) {
      return
    }

    const destroyField = wrapper.querySelector("input[name*='[_destroy]']")

    if (wrapper.dataset.newRecord === "true") {
      wrapper.remove()
    } else if (destroyField) {
      destroyField.value = "1"
      wrapper.style.display = "none"
    } else {
      wrapper.remove()
    }
  }
}
