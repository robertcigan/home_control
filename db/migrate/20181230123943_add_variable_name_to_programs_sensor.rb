class AddVariableNameToProgramsSensor < ActiveRecord::Migration[5.2]
  def change
    #add_column :programs_sensors, :variable_name, :string
    change_column :programs, :code, :text
  end
end
