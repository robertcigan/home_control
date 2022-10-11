namespace "HomeControl.BoardChannel", (exports) ->
  exports.init = ->
    HomeControl.Layout.cable.subscriptions.create "BoardChannel",
      connected: ->
        console.log("connected BoardChannel")
      disconnected: ->
        console.log("disconnected BoardChannel")
      received: (data) ->
        console.log(data)
        device = $("[data-board-id=#{data['id']}]")
        device.data("board-status", data["status"])
        device.data("board-ssid", data["ssid"])
        device.data("board-signal-strength", data["signal-strength"])
        device.trigger("board:update")