import consumer from "channels/consumer"

consumer.subscriptions.create("ProgramChannel", {
  connected() {
    console.log("connected ProgramChannel")
  },

  disconnected() {
    console.log("disconnected ProgramChannel")
  },

  received(data) {
    console.log(data)
    document.querySelectorAll(`[data-program-id="${data["id"]}"]`).forEach((el) => {
      el.dataset.programEnabled = data["enabled"] == null ? "" : String(data["enabled"])
      el.dataset.programRuntime = data["runtime"] == null ? "" : String(data["runtime"])
      el.dataset.programThreadUtilisation = data["thread-utilisation"] == null ? "" : String(data["thread-utilisation"])
      el.dataset.programLastRun = data["last-run"] == null ? "" : String(data["last-run"])
      el.dataset.programLastErrorAt = data["last-error-at"] == null ? "" : String(data["last-error-at"])
      el.dataset.programHasError = data["has-error"] == null ? "" : String(data["has-error"])
      el.dispatchEvent(new CustomEvent("program:update", { bubbles: true }))
    })
  }
})
