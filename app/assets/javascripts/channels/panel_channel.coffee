namespace "HomeControl.PanelChannel", (exports) ->
  exports.init = ->
    HomeControl.Layout.cable.subscriptions.create "PanelChannel",
      connected: ->
        console.log("connected PanelChannel")
      disconnected: ->
        console.log("disconnected PanelChannel")
      received: (data) ->
        console.log(data)
        if $(".panel[data-panel-id=#{data['id']}]").length > 0
          Turbolinks.visit(document.location.href)