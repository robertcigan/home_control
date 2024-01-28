module WidgetsHelper
  def label_height_class(widget)
    widget.show_updated? ? "h-25" : "h-30"
  end

  def indication_height_class(widget)
    if widget.show_label?
      widget.show_updated? ? "h-50" : "h-70"
    else
      widget.show_updated? ? "h-70" : "h-100"
    end
  end
end