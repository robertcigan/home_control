class ProgramsController < ApplicationController
  responders :ajax_modal, :collection
  respond_to :html, only: [:show, :index, :destroy]
  respond_to :js, except: [:show]

  before_action :load_reload, only:  [:create, :update]
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
    if !@reload && @program.save
      flash.now[:notice] = "Program was successfully created." 
    end
    respond_with(@program, location: :programs, reload: @reload)
  end

  def update
    if @reload
      @program.assign_attributes(program_params)
    else
      @program.update(program_params)
    end
    flash.now[:notice] = "Program was successfully updated."  if @program.errors.empty?
    respond_with(@program, location:  :programs, reload: @reload)
  end

  def destroy
    @program.destroy
    flash.now[:notice] = "Program was successfully removed."
    respond_with(@program, location: :programs)
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
    respond_with(@program)
  end
  
  def run
    @program.run
    flash.now[:notice] = "Program #{@program} successfully run"
    respond_with(@program)
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
