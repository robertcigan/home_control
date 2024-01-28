class Widgets::ProgramsController < ApplicationController
  respond_to :js

  load_resource :panel
  load_resource :widget, through: :panel

  skip_before_action :authenticate

  def run
    @program = @widget.program
    if @panel.public_access? || authenticate == true    
      @program.run
      respond_with(@program)
    end
  end
end