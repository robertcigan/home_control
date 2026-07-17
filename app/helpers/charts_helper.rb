module ChartsHelper
  def chart_data_attributes(url, min, max, options = {})
    {
      controller: "chart",
      chart_url_value: url,
      chart_type_value: options[:type] || "line",
      chart_y_title_value: options[:title_y] || "",
      chart_timespan_value: options[:timespan] || "day",
      chart_multi_value: options.fetch(:multi, false),
      chart_min_value: min.iso8601,
      chart_max_value: max.iso8601,
      chart_now_value: Time.current.iso8601
    }
  end

  def chart_window_label(min, timespan)
    format = case timespan
    when "hour"
      :day_and_hour
    when "month"
      :month
    when "year"
      :year
    else
      :date
    end

    I18n.l(min, format: format)
  end

  def device_chart_type(device)
    if device.value_attribute == :value_boolean
      "step-area"
    elsif device.value_attribute == :value_decimal || device.value_attribute == :value_integer
      "line"
    else
      "points"
    end
  end

  def widget_chart_type(widget)
    if widget.chart_type_auto? || widget.chart_type.blank?
      device_chart_type(widget.device)
    elsif widget.chart_type_step_area?
      "step-area"
    else
      widget.chart_type
    end
  end

  def device_chart_y_title(device)
    if device.unit.present?
      device.unit
    else
      ""
    end
  end
end
