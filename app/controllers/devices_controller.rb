class DevicesController < ApplicationController
  responders :collection
  respond_to :html, :turbo_stream

  before_action :load_reload, only: [:create, :update]
  load_and_authorize_resource

  def index
    @search = @devices.ransack(params[:q])
    @search.sorts = ["name ASC"] if @search.sorts.empty?
    @devices = @search.result.page(params[:page]).per(restore_per_page)
    respond_with(@devices)
  end

  def show
    respond_with(@device)
  end

  def new
    respond_with(@device)
  end

  def edit
    respond_with(@device)
  end

  def create
    @device = Device.new(device_params)
    if @reload
      render :new, status: :unprocessable_entity
    else
      if @device.save
        flash[:notice] = "Device was successfully created."
      end
      respond_with(@device, location: :devices)
    end
  end

  def update
    if @reload
      @device.assign_attributes(device_params)
      render :edit, status: :unprocessable_entity
    else
      @device.update(device_params)
      if @device.errors.empty?
        flash[:notice] = "Device was successfully updated."
      end
      respond_with(@device, location: :devices)
    end
  end

  def destroy
    destroy_with_turbo_stream(@device, location: devices_path, notice: "Device was successfully removed.")
  end

  def set
    @device.update(device_set_params)
    head :no_content
  end

  private

  def device_params
    params.require(:device).permit(
      :name, :board_id, :device_type, :pin, :virtual_writable,
      :inverted, :poll, :holding_register_address, :scale,
      :value, :value_boolean, :value_integer, :value_string, :value_decimal, :unit, :modbus_data_type,
      :compression_type, :compression_timespan, :compression_backlog, :compression_last_run_at,
      :days_to_preserve_logs, :log_enabled
    )
  end

  def device_set_params
    params.require(:device).permit(:value, :value_boolean, :value_integer, :value_string, :value_decimal)
  end
end
