class Widgets::DevicesController < ApplicationController
  respond_to :js

  load_resource :panel
  load_resource :widget, through: :panel

  skip_before_action :authenticate

  def set
    @device = @widget.device
    if @panel.public_access? || authenticate == true
      @device.update(device_set_params)
      respond_with(@device)
    end
  end

  private

  def device_set_params
    params.require(:device).permit(:value, :value_boolean, :value_integer, :value_string, :value_decimal)
  end
end
