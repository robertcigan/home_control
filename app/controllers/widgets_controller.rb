class WidgetsController < ApplicationController
  responders :collection
  respond_to :html, :turbo_stream

  load_and_authorize_resource :panel
  load_and_authorize_resource :widget, through: :panel
  before_action :load_reload, only: [:create, :update]

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
    if @reload
      render :new, status: :unprocessable_entity
    else
      if @widget.save
        @panel.push_value_change
      end
      if @widget.errors.empty?
        flash[:notice] = "Widget was successfully created."
      end
      respond_with(@panel, @widget)
    end
  end

  def update
    @widget.assign_attributes(widget_params)
    if @reload
      render :edit, status: :unprocessable_entity
    else
      if @widget.save
        @panel.push_value_change
      end
      if @widget.errors.empty?
        flash[:notice] = "Widget was successfully updated."
      end
      respond_with(@panel, @widget, location: [@panel, :widgets])
    end
  end

  def update_position
    @widget.update(widget_params)
    @panel.push_value_change
    head :no_content
  end

  def destroy
    notice = "Widget was successfully removed."
    if @widget.destroy
      @panel.push_value_change
      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = notice
          render turbo_stream: [
            turbo_stream.remove(@widget),
            *helpers.turbo_stream_flash
          ]
        end
        format.html do
          flash[:notice] = notice
          redirect_to panel_widgets_path(@panel), status: :see_other
        end
      end
    else
      message = @widget.errors.full_messages.to_sentence
      if message.blank?
        message = "Could not remove record."
      end
      respond_to do |format|
        format.turbo_stream do
          flash.now[:alert] = message
          render turbo_stream: helpers.turbo_stream_flash
        end
        format.html do
          flash[:alert] = message
          redirect_to panel_widgets_path(@panel), status: :see_other
        end
      end
    end
  end

  private

  def widget_params
    params.require(:widget).permit(:widget_type, :device_id, :program_id, :x, :y, :w, :h,
      :color_1, :color_2, :icon, :name, :show_updated, :show_label)
  end
end
