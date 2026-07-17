class PanelsController < ApplicationController
  responders :collection
  respond_to :html, :turbo_stream

  skip_before_action :authenticate, if: proc { action_name == 'show' }

  before_action :load_reload, only: [:create, :update]
  load_and_authorize_resource except: :show
  load_resource only: :show

  def index
    @search = @panels.ransack(params[:q])
    @search.sorts = ["name ASC"] if @search.sorts.empty?
    @panels = @search.result.page(params[:page]).per(restore_per_page)
    respond_with(@panels)
  end

  def show
    authorize!(:read, @panel)
    respond_with(@panel) do |format|
      format.html do
        if @panel.public_access? || authenticate == true
          render layout: "panel"
        end
      end
    end
  end

  def new
    @panel = Panel.new
    respond_with(@panel)
  end

  def edit
    @panel.widgets.build if @panel.widgets.empty?
    respond_with(@panel)
  end

  def create
    @panel = Panel.new(panel_params)
    if @reload
      render :new, status: :unprocessable_entity
    else
      if @panel.save
        flash[:notice] = "Panel was successfully created."
      end
      respond_with(@panel)
    end
  end

  def update
    if @reload
      @panel.assign_attributes(panel_params)
      render :edit, status: :unprocessable_entity
    else
      @panel.update(panel_params)
      if @panel.errors.empty?
        flash[:notice] = "Panel was successfully updated."
      end
      respond_with(@panel)
    end
  end

  def destroy
    destroy_with_turbo_stream(@panel, location: panels_path, notice: "Panel layout was successfully removed.")
  end

  def edit_layout
    respond_with(@panel)
  end

  def update_layout
    @panel.update(panel_params)
    if @panel.errors.empty?
      flash[:notice] = "Panel layout was successfully updated."
    end
    respond_with(@panel)
  end

  private

  def panel_params
    params.require(:panel).permit(:name, :column, :row, :public_access,
      widgets_attributes: [
        :id, :widget_type, :device_id, :program_id, :x, :y, :w, :h,
        :color_1, :color_2, :icon, :name, :show_updated, :show_label, :time_window_hours, :chart_type, :_destroy]
    )
  end
end
