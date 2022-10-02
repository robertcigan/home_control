$.rails.allowAction = (element) ->
  message = element.data("confirm")
  submit = element.data("submit") || "Confirm"
  return true unless message
  $link = element.clone()
  $link.removeAttr("class").removeAttr("data-confirm").addClass("btn btn-primary btn-w-m").html(submit)
  $modal_html = $("#confirm-modal")
  $modal_html.find("span#confirm-modal-link").html($link)
  $("p#confirm-text").text(message)
  if element.data("title")
    $modal_html.find(".modal-header h4").text(element.data("title"))
  if element.data("header")
    $modal_html.find("h3").text(element.data("header"))
  hideAjaxModalAfter = false
  if $("#ajax-modal").is(":visible")
    hideAjaxModalAfter = true
    $("#ajax-modal").hide()
    $modal_html.one "hidden.bs.modal", ->
      $("body").addClass("modal-open")
      $("#ajax-modal").show()
  $modal_html.modal
    backdrop: !hideAjaxModalAfter
  $link.one "ajax:success", ->
    $modal_html.modal("hide")
    if hideAjaxModalAfter && $link.data("close-modal-after-success")
      $("#ajax-modal").modal("hide")
      $("#ajax-modal").on "hidden.bs.modal", ->
        $(this).hide()
      hideAjaxModalAfter = false
  return false
