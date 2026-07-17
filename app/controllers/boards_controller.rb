class BoardsController < ApplicationController
  responders :collection
  respond_to :html, :turbo_stream

  before_action :load_reload, only: [:create, :update]
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
    if @reload
      render :new, status: :unprocessable_entity
    else
      if @board.save
        flash[:notice] = "Board was successfully created."
      end
      respond_with(@board)
    end
  end

  def update
    if @reload
      @board.assign_attributes(board_params)
      render :edit, status: :unprocessable_entity
    else
      @board.update(board_params)
      if @board.errors.empty?
        flash[:notice] = "Board was successfully updated."
      end
      respond_with(@board)
    end
  end

  def destroy
    destroy_with_turbo_stream(@board, location: boards_path, notice: "Board was successfully removed.")
  end

  private

  def board_params
    params.require(:board).permit(:name, :ip, :board_type, :slave_address, :data_read_interval, :days_to_preserve_logs)
  end
end
