class WidgetsController < ApplicationController
  responders :ajax_modal, :collection
  respond_to :html, only: [:index, :destroy]
  respond_to :js, except: [:index, :destroy]

  load_and_authorize_resource :panel
  load_and_authorize_resource :widget, through: :panel


  def index
    respond_with(@widgets)
  end

  def new
    respond_with(@widget)
  end

  def edit
    respond_with(@widget)
  end

  def create
    unless @reload
      if @widget.save
        @panel.push_value_change
      end
      flash.now[:notice] = "Widget was successfully created." if @widget.errors.empty? 
    end
    respond_with(@panel, @widget, reload: @reload)
  end

  def update
    @widget.assign_attributes(widget_params)
    unless @reload
      if @widget.save
        @panel.push_value_change
      end
      flash.now[:notice] = "Widget was successfully updated." if @widget.errors.empty?
    end
    respond_with(@panel, @widget, location: [@panel, :widgets], reload: @reload)
  end
  
  def update_position
    @widget.update(widget_params)
    @panel.push_value_change
    respond_with(@widget)
  end

  def destroy
    @widget.destroy
    flash.now[:notice] = "Widget was successfully removed."
    @panel.push_value_change
    respond_with(@panel, @widget)
  end

  private

  def widget_params
    params.require(:widget).permit(:widget_type, :device_id, :program_id, :x, :y, :w, :h, 
      :color_1, :color_2, :icon, :name, :show_updated)
  end
end
