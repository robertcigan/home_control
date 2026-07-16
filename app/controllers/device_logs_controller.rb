class DeviceLogsController < ApplicationController
  helper ChartsHelper

  respond_to :html, :json

  layout false

  load_and_authorize_resource :device
  load_and_authorize_resource through: :device

  def index
    @search = @device_logs.ransack(params[:q])
    @search.sorts = ["created_at DESC"] if @search.sorts.empty?
    @device_logs = @search.result.page(params[:page]).per(restore_per_page)
    respond_with(@device_logs)
  end

  def chart
    @timespan = params[:timespan] || "day"
    if params[:min] && params[:max]
      @min = Time.zone.parse(params[:min])
      @max = Time.zone.parse(params[:max])
    else
      case @timespan
      when "hour"
        @min = Time.current.beginning_of_hour
        @max = Time.current.end_of_hour
      when "day"
        @min = Time.current.beginning_of_day
        @max = Time.current.end_of_day
      when "week"
        @min = Time.current.beginning_of_week
        @max = Time.current.end_of_week
      when "month"
        @min = Time.current.beginning_of_month
        @max = Time.current.end_of_month
      when "year"
        @min = Time.current.beginning_of_year
        @max = Time.current.end_of_year
      end
    end

    chart_type = if @device.value_attribute == :value_boolean
      "step-area"
    elsif @device.value_attribute == :value_decimal || @device.value_attribute == :value_integer
      "line"
    else
      "points"
    end
    title_y = if @device.value_attribute == :value_boolean
      "On/Off"
    elsif @device.unit.present?
      @device.unit
    else
      "Value"
    end

    @chart_data_attributes = helpers.chart_data_attributes(
      chart_device_device_logs_path(@device, format: :json),
      @min,
      @max,
      type: chart_type,
      title_y: title_y,
      timespan: @timespan,
      multi: false
    )

    respond_with(@device_logs) do |format|
      format.html
      format.json do
        data = DeviceLog.chart_series(@device, @min, @max)
        if @device.value_attribute
          if (initial_value = @device.device_logs.where("created_at < ?", @min).order("created_at DESC").first)
            data.unshift([(@min - 1.send(@timespan.to_sym)).to_s, initial_value.numeric_chart_value])
          end
          if (newer_value = @device.device_logs.where("created_at > ?", @max).order(:created_at).first)
            data.push([newer_value.created_at.to_s, newer_value.numeric_chart_value])
          end
        end
        render json: data
      end
    end
  end
end
