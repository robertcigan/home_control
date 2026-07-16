class Widgets::ProgramsController < ApplicationController
  respond_to :html

  load_resource :panel
  load_resource :widget, through: :panel

  skip_before_action :authenticate

  def run
    @program = @widget.program
    if @panel.public_access? || authenticate == true
      @program.run
    end
    head :no_content
  end
end
