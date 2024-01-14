class BoardsController < ApplicationController
  responders :ajax_modal, :collection
  respond_to :html, only: [:show, :index, :destroy]
  respond_to :js, except: [:show]

  before_action :load_reload, only:  [:create, :update]
  load_and_authorize_resource

  def index
    @search = @boards.ransack(params[:q])
    @search.sorts = ["name ASC"] if @search.sorts.empty?
    @boards = @search.result.page(params[:page]).per(restore_per_page)
    respond_with(@boards)
  end

  def show
    respond_with(@board)
  end

  def new
    respond_with(@board)
  end

  def edit
    respond_with(@board)
  end

  def create
    if !@reload && @board.save
      flash.now[:notice] = "Board was successfully created." 
    end
    respond_with(@board, reload: @reload)
  end

  def update
    if @reload
      @board.assign_attributes(board_params)
    else
      @board.update(board_params)
    end
    flash.now[:notice] = "Board was successfully updated." if @board.errors.empty?
    respond_with(@board, reload: @reload)
  end

  def destroy
    @board.destroy
    flash.now[:notice] = "Board was successfully removed."
    respond_with(@board)
  end

  private

  def board_params
    params.require(:board).permit(:name, :ip, :board_type, :slave_address, :data_read_interval, :days_to_preserve_logs)
  end
end
