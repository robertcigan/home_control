# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

namespace "HomeControl.Widgets", (exports) ->
  exports.initIndex = (column, row)->
    $(".grid-stack-item").on "widget:update", ->
      $(this).find("input[data-gs=x]").val($(this).attr("gs-x"))
      $(this).find("input[data-gs=y]").val($(this).attr("gs-y"))
      $(this).find("input[data-gs=w]").val($(this).attr("gs-w"))
      $(this).find("input[data-gs=h]").val($(this).attr("gs-h"))
      $(this).find("form").submit()
      HomeControl.Layout.autoFontResize($(this))

    grid = GridStack.init
      float: true
      disableOneColumnMode: true
      alwaysShowResizeHandle: /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)
      column: column
      row: row
      
    grid.on "change", (event, items) ->
      items.forEach (item) ->
        $(item.el).trigger("widget:update")

    HomeControl.Devices.initDevicesUpdates()

    $(".grid-stack-item").on "widget:resize", (event) ->
      HomeControl.Layout.autoFontResize($(this))
    HomeControl.Layout.autoFontResize()
    $(window).on "resize", ->
      HomeControl.Layout.autoFontResize()
  
  exports.initForm = -> 
    HomeControl.Layout.initSelect(true)
    HomeControl.Layout.initReloadForm()
    
