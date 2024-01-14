class DevicesController < ApplicationController
  responders :ajax_modal, :collection
  respond_to :html, only: [:show, :index, :destroy]
  respond_to :js, except: [:show]

  before_action :load_reload, only:  [:create, :update]
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
    if !@reload && @device.save
      flash.now[:notice] = "Device was successfully created." 
    end
    respond_with(@device, location: :devices, reload: @reload)
  end

  def update
    if @reload
      @device.assign_attributes(device_params)
    else
      @device.update(device_params)
    end
    flash.now[:notice] = "Device was successfully updated."  if @device.errors.empty?
    respond_with(@device, location:  :devices, reload: @reload)
  end

  def destroy
    @device.destroy
    flash.now[:notice] = "Device was successfully removed."
    respond_with(@device, location:  :devices)
  end

  def set
    @device.update(device_set_params)
    respond_with(@device)
  end

  private

  def device_params
    params.require(:device).permit(
      :name, :board_id, :device_type, :pin, 
      :inverted, :poll, :holding_register_address, :scale,
      :value, :value_boolean, :value_integer, :value_string, :value_decimal, :unit, :modbus_data_type,
      :compression_type, :compression_timespan, :compression_backlog, :compression_last_run_at,
      :days_to_preserve_logs
    )
  end

  def device_set_params
    params.require(:device).permit(:value, :value_boolean, :value_integer, :value_string, :value_decimal)
  end
end
