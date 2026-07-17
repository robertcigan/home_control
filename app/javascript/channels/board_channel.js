import consumer from "channels/consumer"

consumer.subscriptions.create("BoardChannel", {
  connected() {
    console.log("connected BoardChannel")
  },

  disconnected() {
    console.log("disconnected BoardChannel")
  },

  received(data) {
    console.log(data)
    document.querySelectorAll(`[data-board-id="${data["id"]}"]`).forEach((el) => {
      el.dataset.boardStatus = data["status"] == null ? "" : String(data["status"])
      el.dataset.boardSsid = data["ssid"] == null ? "" : String(data["ssid"])
      el.dataset.boardSignalStrength = data["signal-strength"] == null ? "" : String(data["signal-strength"])
      el.dispatchEvent(new CustomEvent("board:update", { bubbles: true }))
    })
  }
})
