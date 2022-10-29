namespace "HomeControl.Layout", (exports) ->
  exports.cable = null
  exports.init = ->
    initAjaxModal()
    initSelectOnLoad()
    initCable()
    $(document).on "turbolinks:load", ->
      exports.initSearchField()
      exports.initSelect()
      exports.initReloadForm()
      initAutosubmit()
  
  initCable = ->
    exports.cable = ActionCable.createConsumer()
    HomeControl.BoardChannel.init()
    HomeControl.DeviceChannel.init()
    HomeControl.PanelChannel.init()
    HomeControl.ProgramChannel.init()
  
  initAutosubmit = ->
    exports.initAutosubmitCheckbox()

  exports.initAutosubmitCheckbox = ->
    $("input[type=checkbox]").on "change", ->
      if $(this).data("autosubmit")
        $(this).parents("form").submit()

  initAjaxModal = ->
    $(document).on "turbolinks:load", ->
      loadingContent = $("#ajax-modal-content").html()
      $ajaxModal = $("#ajax-modal").modal
        backdrop: "static"
        show: false
      $("#ajax-modal").on "hidden.bs.modal", ->
        $("#ajax-modal-content").html(loadingContent)
        $("#ajax-modal .modal-dialog").attr("class", "modal-dialog")

    $(document).on "click", "[data-toggle=ajax-modal]", ->
      openAjaxModal = =>
        $this = $(this)
        $("#ajax-modal .modal-title").text($this.data("title"))
        if $this.data("class")
          $("#ajax-modal .modal-dialog").addClass($this.data("class"))
        $.getScript $this.attr("href"), ->
          $("#ajax-modal").trigger("ajaxmodalloaded")
        $("#ajax-modal").modal("show")
      if $("#ajax-modal").hasClass("in")
        $("#ajax-modal").modal("hide")
        $("#ajax-modal").one "hidden.bs.modal", openAjaxModal
      else
        openAjaxModal()
      false
      
  initDateTimePickerIcons = ->
    $.fn.datetimepicker.Constructor.Default = $.extend {}, $.fn.datetimepicker.Constructor.Default,
      icons:
        date: "fa fa-calendar"
        time: "fa fa-clock-o"
        up: "fa fa-chevron-up"
        down: "fa fa-chevron-down"
        previous: "fa fa-chevron-left"
        next: "fa fa-chevron-right"
        today: "fa fa-crosshairs"
        clear: "fa fa-trash-o"
        close: "fa fa-times"

  exports.initDateTimePicker = ->
    $(".datetimepicker").each ->
      $(this).datetimepicker
        format: $(this).find("input").data("date-format")
        useCurrent: false
    $(".datetimepicker").on "change.datetimepicker", ->
      if $(this).find("input[data-autosubmit]").length > 0
        $(this).parents("form").submit()

  exports.initSearchField = (selector = "input.search-field") ->
    $(selector).each ->
      $(this).on "input", jQuery.debounce ($(this).data("debounce-time") || 1000), false, ->
        $(this).parents("form").submit()

  initSelectOnLoad = ->
    $.fn.select2.defaults.set "theme", "bootstrap4"
    $.fn.select2.defaults.set "width", "100%"
    $.fn.select2.defaults.set "placeholder", ""
    $.fn.select2.defaults.set "allowClear", true
    $.fn.select2.defaults.set "minimumResultsForSearch", 7

  exports.initSelect = (modal = false, context = "") -> # defaults: modal: false,ajax: false, or provide element scope
    $selectSelector = switch
      when modal == true then $("body #ajax-modal #{context}")
      when modal == false then $("body *:not(#ajax-modal) #{context}")
      else $(modal)
    $dropdownParent = null

    formatWithLabel = (item) ->
      return item.html || item.text
    formatWithLabelSelection = (item) ->
      html_data = $(item.element).data("html")
      return item.html || html_data || item.text

    $selectSelector.find("select[data-ajax-select]").select2(
      minimumResultsForSearch: 0
      allowClear: true
      dropdownParent: $dropdownParent
      ajax:
        url: ->
          $(this).data("source-url")
        dataType: "json"
        delay: 250
        data: (params) ->
          prms = { }
          if $(this).data("secondary-search-term") != undefined
            prms[$(this).data("secondary-search-term")] = $(this).data("secondary-search-value")
          prms[$(this).data("search-term")] = params.term
          if $(this).data("sort-by") != undefined
            prms["s"] = $(this).data("sort-by")
          { q: prms, page: params.page}
        processResults: (data, params) ->
          params.page = params.page || 1;
          {
            results: data.items,
            pagination: {
              more: (params.page * 25) < data.total_count
            }
          }
        cache: true
      templateResult: formatWithLabel,
      templateSelection: formatWithLabelSelection
      escapeMarkup: (markup) ->
        return markup
    ).on "change", ->
      if $(this).data("autosubmit")
        $(this).parents("form").submit()
    .on "select2:select", ->
      $(this).focus()
    .on "select2:close", ->
      $(this).focus()

    $selectSelector.find("select:not([data-ajax-select])").select2(
      dropdownParent: $dropdownParent
    ).on "change", ->
      if $(this).data("autosubmit")
        $(this).parents("form").submit()
    .on "select2:select", ->
      $(this).focus()
    .on "select2:close", ->
      $(this).focus()

   exports.initReloadForm = ->
    $("form").on "change", "[data-reload]", ->
      $form = $(this).parents("form")
      reload_tag = $("<input type='hidden' name='reload' value='1'/>")
      $form.append(reload_tag)
      $form.submit()
      true

  exports.showFlash = (text, alert_type) ->
    $.notify {
      message: text
    },
      type: alert_type
      animate:
        enter: 'animate__animated animate__backInDown'
        exit: 'animate__animated animate__backOutUp'
      placement:
        from: "top"
        align: "center"
  
  exports.initContentOnLoad = ->
    $("[data-onload-content]").each ->
      exports.loadContent(this)
    false

  exports.loadContent = (elem) ->
    $elem = $(elem)
    $.ajax
      url: $elem.data("onload-content")
      dataType: "html"
      cache: false
      success: (data, textStatus, jqXHR) ->
        $elem.replaceWith(data)

  exports.autoFontResize = (container = "body") ->
    $(container).find(".resizable-font-size").each ->
      parent_container = $(this).parent()
      font_size = parent_container.height() * 0.8 
      max_width = parent_container.width() * 0.6
      $(this).css("font-size", font_size)
      if $(this).width() > max_width
        font_size = font_size * max_width / $(this).width()
      if font_size > 50
        font_size = (font_size - 50) * 0.3 + 50
      # multi line text recalculation
      $(this).css("font-size", font_size)
      if $(this).height() > parent_container.height() * 0.8 
        font_size = font_size * parent_container.height() * 0.8  / $(this).height()
      $(this).css("font-size", font_size)

HomeControl.Layout.init()