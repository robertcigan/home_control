module ApplicationHelper
  def page_title(title)
    content_for :title do
      title.to_s
    end
    title.to_s
  end

  def ajax_modal_render(options)
    raw %{$("#ajax-modal-content").html("#{escape_javascript(render(options))}");}
  end

  def replace_with_render(selector, *render_options)
     %{$("#{selector}").replaceWith("#{escape_javascript(render(*render_options))}");}.html_safe
  end

  def replace_content_with_render(selector, *render_options)
    %{$("#{selector}").html("#{escape_javascript(render(*render_options))}");}.html_safe
  end

  def states_data_options(options = {})
    { "data-options-us": options_for_select([[]] + state_collection("US")) }.merge(options)
  end

  def state_collection(country_code = "US")
    Carmen::Country.coded(country_code).subregions.map{ |state| [state.name, state.code] }
  end

  def show_flash()
    if flash[:notice]
      "HomeControl.Layout.showFlash(\"#{flash[:notice]}\", 'success');".html_safe
    elsif flash[:alert]
      "HomeControl.Layout.showFlash(\"#{flash[:alert]}\", 'alert');".html_safe
    end
  end
  
  def refresh_list_by_script(form_selector)
    %{if ($(".pagination").data("page") != undefined) { $.getScript($("#{form_selector}").attr("action") + "?" +  $("#{form_selector}").serialize() + "&page=" + $(".pagination").data("page")); } else { $.getScript($("#{form_selector}").attr("action") + "?" +  $("#{form_selector}").serialize()); } }.html_safe
  end
end
