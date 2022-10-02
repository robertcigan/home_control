class AddLastErrorMessageToProgram < ActiveRecord::Migration[5.2]
  def change
    add_column :programs, :last_error_message, :text
    add_column :programs, :last_run, :datetime
  end
end
