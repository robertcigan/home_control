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

  # Chart widgets are usually taller; a 30% label would dominate the tile.
  def chart_label_height_class
    "h-15"
  end

  def chart_footer_height_class
    "h-15"
  end

  def chart_body_height_class(widget)
    if widget.show_label?
      if widget.show_updated?
        "h-70"
      else
        "h-85"
      end
    else
      if widget.show_updated?
        "h-85"
      else
        "h-100"
      end
    end
  end
end
