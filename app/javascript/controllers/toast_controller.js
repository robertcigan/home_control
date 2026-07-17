import { Controller } from "@hotwired/stimulus"
import "bootstrap"

export default class extends Controller {
  connect() {
    const toast = bootstrap.Toast.getOrCreateInstance(this.element, {
      delay: 4000
    })
    toast.show()
  }
}
