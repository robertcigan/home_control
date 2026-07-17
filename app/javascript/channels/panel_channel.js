import consumer from "channels/consumer"

consumer.subscriptions.create("PanelChannel", {
  connected() {
    console.log("connected PanelChannel")
  },

  disconnected() {
    console.log("disconnected PanelChannel")
  },

  received(data) {
    console.log(data)
    if (document.querySelector(`.panel[data-panel-id="${data["id"]}"]`)) {
      window.Turbo.visit(location.href)
    }
  }
})