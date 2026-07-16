class ProgramsController < ApplicationController
  responders :collection
  respond_to :html, :turbo_stream

  before_action :load_reload, only: [:create, :update]
  load_and_authorize_resource

  def index
    @search = @programs.ransack(params[:q])
    @search.sorts = ["name ASC"] if @search.sorts.empty?
    @programs = @search.result.page(params[:page]).per(restore_per_page)
    respond_with(@programs)
  end

  def show
    respond_with(@program)
  end

  def new
    if params[:program_id]
      @program = Program.find(params[:program_id]).amoeba_dup
    end
    respond_with(@program)
  end

  def edit
    respond_with(@program)
  end

  def create
    @program = Program.new(program_params)
    if @reload
      render :new, status: :unprocessable_entity
    else
      if @program.save
        flash[:notice] = "Program was successfully created."
      end
      respond_with(@program, location: :programs)
    end
  end

  def update
    if @reload
      @program.assign_attributes(program_params)
      render :edit, status: :unprocessable_entity
    else
      @program.update(program_params)
      if @program.errors.empty?
        flash[:notice] = "Program was successfully updated."
      end
      respond_with(@program, location: :programs)
    end
  end

  def destroy
    destroy_with_turbo_stream(@program, location: programs_path, notice: "Program was successfully removed.")
  end

  def set
    @program.assign_attributes(program_set_params)
    changes = @program.changes
    if @program.save
      if changes["enabled"]
        flash.now[:notice] = "Program #{@program} #{@program.enabled? ? 'turned on' : 'turned off'}"
      end
    else
      flash.now[:alert] = "Program #{@program} update errors"
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: helpers.turbo_stream_flash
      end
      format.html do
        flash[:notice] = flash.now[:notice] if flash.now[:notice].present?
        flash[:alert] = flash.now[:alert] if flash.now[:alert].present?
        redirect_back fallback_location: @program, status: :see_other
      end
    end
  end

  def run
    @program.run
    if params[:silent]
      head :no_content
    else
      flash.now[:notice] = "Program #{@program} successfully run"

      respond_to do |format|
        format.turbo_stream do
          streams = helpers.turbo_stream_flash
          streams << turbo_stream.replace(
            "#{helpers.dom_id(@program)}_output_log",
            partial: "programs/output_log",
            locals: { program: @program }
          )
          render turbo_stream: streams
        end
        format.html do
          flash[:notice] = flash.now[:notice]
          redirect_back fallback_location: @program, status: :see_other
        end
      end
    end
  end

  private

  def program_params
    params.require(:program).permit(:name, :program_type, :code, :repeat_every, :enabled,
      programs_devices_attributes: [:id, :device_id, :variable_name, :trigger, :_destroy]
    )
  end

  def program_set_params
    params.require(:program).permit(:enabled)
  end
end
