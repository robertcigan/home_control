# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

namespace "HomeControl.Programs", (exports) ->
  exports.initIndex = ->
    
  exports.initList = ->
    exports.initProgramsUpdates();

  exports.initShow = ->
    exports.initProgramsUpdates();
    
  exports.initForm = ->
    HomeControl.Layout.initSelect(true)
    HomeControl.Layout.initReloadForm()

    textArea = document.getElementById("program_code")
    myCodeMirror = CodeMirror.fromTextArea textArea, 
      tabSize: 2
      indentUnit: 2
      lineNumbers: true

    $('#programs_devices').on 'cocoon:after-insert', ->
      HomeControl.Layout.initSelect($(this))

    $("#hide_devices").on "click", ->
      $("#devices-section").hide()
      $("#code-section").addClass("col-sm-12").removeClass("col-sm-6")
      $(this).hide()
      $("#show_devices").show()
      return false

    $("#show_devices").hide().on "click", ->
      $("#devices-section").show()
      $("#code-section").addClass("col-sm-6").removeClass("col-sm-12")
      $(this).hide()
      $("#hide_devices").show()
      return false
  
  exports.initProgramsUpdates = ->
    $( ".program" ).on "program:update", (event) ->
      program = $(this)
      if program.data("program-enabled") == "true" || program.data("program-enabled") == true
        program.trigger("program:on")
      else if program.data("program-enabled") == "false" || program.data("program-enabled") == false
        program.trigger("program:off")
      if program.data("program-has-error") == "true" || program.data("program-has-error") == true
        program.trigger("program:error-on")
      else if program.data("program-has-error") == "false" || program.data("program-has-error") == false
        program.trigger("program:error-off")
      program.find(".runtime").text(program.data("program-runtime"))
      program.find(".thread-utilisation").text(program.data("program-thread-utilisation"))
      if program.data("program-last-run")
        program.find(".last-run").text(program.data("program-last-run"))
      else program.find(".last-run").text("")
      if program.data("program-last-error-at")
        program.find(".last-error-at").text(program.data("program-last-error-at"))
      else
        program.find(".last-error-at").text("")
    .on "program:on", (event) ->
      $(this).removeClass("program-off").addClass("program-on")
    .on "program:off", (event) ->
      $(this).removeClass("program-on").addClass("program-off")
    .on "program:error-on", (event) ->
      $(this).addClass("program-error")
    .on "program:error-off", (event) ->
      $(this).removeClass("program-error")

    $( ".program" ).trigger("program:update")