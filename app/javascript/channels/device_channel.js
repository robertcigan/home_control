import consumer from "channels/consumer"

consumer.subscriptions.create("DeviceChannel", {
  connected() {
    console.log("connected DeviceChannel")
  },

  disconnected() {
    console.log("disconnected DeviceChannel")
  },

  received(data) {
    console.log(data)
    document.querySelectorAll(`[data-device-id="${data["id"]}"]`).forEach((el) => {
      el.dataset.deviceStatus = data["status"] == null ? "" : String(data["status"])
      el.dataset.deviceIndication = data["indication"] == null ? "" : String(data["indication"])
      el.dataset.deviceUpdated = data["updated"] == null ? "" : String(data["updated"])
      el.dataset.deviceValue = data["value"] == null ? "" : String(data["value"])
      el.dispatchEvent(new CustomEvent("device:update", { bubbles: true }))
    })
  }
})
