class BoardLogsController < ApplicationController
  helper ChartsHelper

  respond_to :html, :json

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

    @chart_data_attributes = helpers.chart_data_attributes(
      chart_board_board_logs_path(@board, format: :json),
      @min,
      @max,
      type: "step-area",
      title_y: "On/Off",
      timespan: @timespan,
      multi: true
    )

    respond_with(@board_logs) do |format|
      format.html
      format.json do
        connection_data = BoardLog.chart_connection_series(@board, @min, @max)
        if (initial_value = @board.board_logs.where("created_at < ?", @min).order("created_at DESC").first)
          connection_data.unshift([(@min - 1.send(@timespan.to_sym)).to_s, initial_value.chart_data_status.last])
        end
        if (current_value = @board.board_logs.where("created_at > ?", @max).order(:created_at).first)
          connection_data.push(current_value.chart_data_status)
        else
          connection_data.push([@max.to_s, @board.chart_data_status])
        end

        signal_strength_data = BoardLog.chart_signal_series(@board, @min, @max)
        if (initial_value = @board.board_logs.where("created_at < ?", @min).order("created_at DESC").first)
          signal_strength_data.unshift([(@min - 1.send(@timespan.to_sym)).to_s, initial_value.chart_data_signal_strength.last])
        end
        if (current_value = @board.board_logs.where("created_at > ?", @max).order(:created_at).first)
          signal_strength_data.push(current_value.chart_data_signal_strength)
        else
          signal_strength_data.push([@max.to_s, @board.chart_data_signal_strength])
        end

        data = []
        data << { name: "Connection", data: connection_data }
        data << { name: "Signal Strength", data: signal_strength_data }

        render json: data
      end
    end
  end
end
