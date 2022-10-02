class DeviceLogsController < ApplicationController
  helper ChartsHelper

  respond_to :html
  respond_to :js

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
    @chart_options = case @device.value_attribute
    when :value_decimal, :value_integer
      helpers.chart_options(@min, @max, title_y: @device.unit.present? ? @device.unit : "Value")
    when :value_boolean
      helpers.chart_options(@min, @max, type: :area, title_y: "On/Off", stepped: true)
    else
      helpers.chart_options(@min, @max, lines: false)
    end
  
    respond_with(@device_logs) do |format|
      format.json do
        data = @device.device_logs.where("created_at >= ? AND created_at <=? ", @min, @max).order(:created_at).collect(&:chart_data)
        if @device.value_attribute
          if (initial_value = @device.device_logs.where("created_at < ?", @min).order("created_at DESC").first)
            data.unshift([(@min - 1.send(@timespan.to_sym)).to_s, initial_value.chart_data.last])
          end
          if (newer_value = @device.device_logs.where("created_at > ?", @max).order(:created_at).first)
            data.push(newer_value.chart_data)
          else
            #data.push([@max.to_s, @device.get_current_chart_data])
          end
        end
        render json: data
      end
    end
  end
end