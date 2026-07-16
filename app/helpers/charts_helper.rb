module ChartsHelper
  def chart_data_attributes(url, min, max, options = {})
    {
      controller: "chart",
      chart_url_value: url,
      chart_type_value: options[:type] || "line",
      chart_y_title_value: options[:title_y] || "Value",
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
end
