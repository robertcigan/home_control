namespace "HomeControl.DeviceChannel", (exports) ->
  exports.init = ->
    HomeControl.Layout.cable.subscriptions.create "DeviceChannel",
      connected: ->
        console.log("connected DeviceChannel")
      disconnected: ->
        console.log("disconnected DeviceChannel")
      received: (data) ->
        console.log(data)
        device = $("[data-device-id=#{data['id']}]")
        device.data("device-status", data["status"])
        device.data("device-indication", data["indication"])
        device.data("device-updated", data["updated"])
        device.data("device-value", data["value"])
        device.trigger("device:update")