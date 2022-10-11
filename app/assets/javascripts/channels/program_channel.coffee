namespace "HomeControl.ProgramChannel", (exports) ->
  exports.init = ->
    HomeControl.Layout.cable.subscriptions.create "ProgramChannel",
      connected: ->
        console.log("connected ProgramChannel")
      disconnected: ->
        console.log("disconnected ProgramChannel")
      received: (data) ->
        console.log(data)
        program = $("[data-program-id=#{data['id']}]")
        program.data("program-enabled", data["enabled"])
        program.data("program-runtime", data["runtime"])
        program.data("program-thread-utilisation", data["thread-utilisation"])
        program.data("program-last-run", data["last-run"])
        program.data("program-last-error-at", data["last-error-at"])
        program.data("program-has-error", data["has-error"])
        program.trigger("program:update")