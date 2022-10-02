class AddRuntimeToProgram < ActiveRecord::Migration[5.2]
  def change
    add_column :programs, :runtime, :integer
  end
end
