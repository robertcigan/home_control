# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

namespace "HomeControl.Panels", (exports) ->
  exports.initIndex = ->

  exports.initList = ->

  exports.initForm = ->
    HomeControl.Layout.initSelect(true)
    HomeControl.Layout.initReloadForm()

    $('#widgets').on 'cocoon:after-insert', ->
      HomeControl.Layout.initSelect($(this))

  exports.initShow = (column, row) ->
    grid = GridStack.init
      float: true
      disableOneColumnMode: true
      staticGrid: true
      column: column
      row: row
      cellHeight: "#{100.0/row}%"
    HomeControl.Devices.initDevicesUpdates()
    HomeControl.Programs.initProgramsUpdates()

    $(".grid-stack-item").on "widget:resize", (event) ->
      HomeControl.Layout.autoFontResize($(this))
    HomeControl.Layout.autoFontResize()
    $(window).on "resize", ->
      HomeControl.Layout.autoFontResize()
      

