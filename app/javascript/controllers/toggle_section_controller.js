import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.hideButton = document.getElementById("hide_devices")
    this.showButton = document.getElementById("show_devices")
    this.devicesSection = document.getElementById("devices-section")
    this.codeSection = document.getElementById("code-section")

    if (this.showButton) {
      this.showButton.style.display = "none"
    }

    this.boundHide = this.hideDevices.bind(this)
    this.boundShow = this.showDevices.bind(this)

    if (this.hideButton) {
      this.hideButton.addEventListener("click", this.boundHide)
    }

    if (this.showButton) {
      this.showButton.addEventListener("click", this.boundShow)
    }
  }

  disconnect() {
    if (this.hideButton) {
      this.hideButton.removeEventListener("click", this.boundHide)
    }

    if (this.showButton) {
      this.showButton.removeEventListener("click", this.boundShow)
    }
  }

  hideDevices(event) {
    event.preventDefault()

    if (this.devicesSection) {
      this.devicesSection.style.display = "none"
    }

    if (this.codeSection) {
      this.codeSection.classList.add("col-sm-12")
      this.codeSection.classList.remove("col-sm-6")
    }

    if (this.hideButton) {
      this.hideButton.style.display = "none"
    }

    if (this.showButton) {
      this.showButton.style.display = ""
    }
  }

  showDevices(event) {
    event.preventDefault()

    if (this.devicesSection) {
      this.devicesSection.style.display = ""
    }

    if (this.codeSection) {
      this.codeSection.classList.add("col-sm-6")
      this.codeSection.classList.remove("col-sm-12")
    }

    if (this.showButton) {
      this.showButton.style.display = "none"
    }

    if (this.hideButton) {
      this.hideButton.style.display = ""
    }
  }
}
