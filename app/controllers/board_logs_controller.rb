class BoardLogsController < ApplicationController
  helper ChartsHelper

  respond_to :html
  respond_to :js

  layout false  

  load_and_authorize_resource :board
  load_and_authorize_resource through: :board

  def index
    @search = @board_logs.ransack(params[:q])
    @search.sorts = ["created_at DESC"] if @search.sorts.empty?
    @board_logs = @search.result.page(params[:page]).per(restore_per_page)
    respond_with(@board_logs)
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

    @chart_options = helpers.chart_options(@min, @max, type: :area, title_y: "On/Off", stepped: true)
    
    respond_with(@board_logs) do |format|
      format.json do
        data = []
        
        connection_data = @board.board_logs.where("created_at >= ? AND created_at <=? ", @min, @max).order(:created_at).collect(&:chart_data_status)
        if (initial_value = @board.board_logs.where("created_at < ?", @min).order("created_at DESC").first)
          connection_data.unshift([(@min - 1.send(@timespan.to_sym)).to_s, initial_value.chart_data_status.last])
        end
        if (current_value = @board.board_logs.where("created_at > ?", @max).order(:created_at).first)
          connection_data.push(current_value.chart_data_status)
        else
          connection_data.push([@max.to_s, @board.chart_data_status])
        end

        signal_strength_data = @board.board_logs.where("created_at >= ? AND created_at <=? ", @min, @max).order(:created_at).collect(&:chart_data_signal_strength)
        if (initial_value = @board.board_logs.where("created_at < ?", @min).order("created_at DESC").first)
          signal_strength_data.unshift([(@min - 1.send(@timespan.to_sym)).to_s, initial_value.chart_data_signal_strength.last])
        end
        if (current_value = @board.board_logs.where("created_at > ?", @max).order(:created_at).first)
          signal_strength_data.push(current_value.chart_data_signal_strength)
        else
          signal_strength_data.push([@max.to_s, @board.chart_data_signal_strength])
        end

        data << { name: "Connection", data: connection_data }
        data << { name: "Signal Strength", data: signal_strength_data }

        render json: data
      end
    end
  end
end