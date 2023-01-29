# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

namespace "HomeControl.Boards", (exports) ->
  exports.initIndex = ->
  
  exports.initList = ->
    exports.initBoardsUpdates();
  
  exports.initShow = ->
    HomeControl.Layout.initContentOnLoad()
    exports.initBoardsUpdates();

  exports.initForm = ->
    HomeControl.Layout.initSelect(true)
    HomeControl.Layout.initReloadForm()

  exports.initBoardsUpdates = ->
    $(".board").on "board:update", (event) ->
      board = $(this)
      if board.data("board-status") == "true" || board.data("board-status") == true
        board.trigger("board:on")
      else if board.data("board-status") == "false" || board.data("board-status") == false
        board.trigger("board:off")
      
      if board.data("board-ssid")
        board.find(".ssid").text(board.data("board-ssid"))
      else
        board.find(".ssid").text("")
      
      if board.data("board-signal-strength")
        board.find(".signal-strength").text(board.data("board-signal-strength"))
      else
        board.find(".signal-strength").text("")
    .on "board:on", (event) ->
      $(this).removeClass("board-off").addClass("board-on")
    .on "board:off", (event) ->
      $(this).removeClass("board-on").addClass("board-off")
    $(".board").trigger("board:update")
