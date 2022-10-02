# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

namespace "HomeControl.BoardLogs", (exports) ->
  exports.initIndex = ->
    HomeControl.Layout.initSelect(false, "#board_logs_search_form")
  
  exports.initChart = ->

