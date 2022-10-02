class AddEnabledToProgram < ActiveRecord::Migration[5.2]
  def change
    add_column :programs, :enabled, :boolean, default: false, null: false
  end
end
