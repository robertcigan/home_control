class Widgets::ChartsController < ApplicationController
  respond_to :json

  load_resource :panel
  load_resource :widget, through: :panel

  skip_before_action :authenticate

  def show
    if !@widget.widget_type_chart? || @widget.device.nil?
      head :not_found
    else
      allowed = @panel.public_access? || authenticate == true
      if performed?
        # Basic-auth challenge already rendered
      elsif !allowed
        head :unauthorized
      else
        render json: chart_series_data
      end
    end
  end

  private

  def chart_series_data
    device = @widget.device
    max = Time.current
    min = max - @widget.time_window_hours.hours
    data = DeviceLog.chart_series(device, min, max)

    initial_value = device.device_logs.where("created_at < ?", min).order("created_at DESC").first
    if initial_value
      data.unshift([min.to_s, initial_value.numeric_chart_value])
    end

    chart_value = device.numeric_chart_value
    if chart_value != nil
      data.push([max.to_s, chart_value])
    end

    data
  end
end
