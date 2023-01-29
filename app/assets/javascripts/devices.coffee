# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

namespace "HomeControl.Devices", (exports) ->
  exports.initIndex = ->
    
  exports.initList = ->
    exports.initDevicesUpdates();
  
  exports.initShow = ->
    HomeControl.Layout.initContentOnLoad()
    exports.initDevicesUpdates();

  exports.initForm = ->
    HomeControl.Layout.initSelect(true)
    HomeControl.Layout.initReloadForm()

  exports.initDevicesUpdates = ->
    $( ".device" ).on "device:update", (event) ->
      device = $(this)
      if device.data("device-status") == "true" || device.data("device-status") == true
        device.trigger("device:on")
      else if device.data("device-status") == "false" || device.data("device-status") == false
        device.trigger("device:off")
      if device.data("device-updated")
        device.find(".updated").text(device.data("device-updated"))
      else
        device.find(".updated").text("")
      device.find(".indication").text(device.data("device-indication"))
      device.parents(".grid-stack-item").trigger("widget:resize")
    .on "device:on", (event) ->
      $(this).removeClass("device-off").addClass("device-on")
    .on "device:off", (event) ->
      $(this).removeClass("device-on").addClass("device-off")
    $( ".device" ).trigger("device:update")
