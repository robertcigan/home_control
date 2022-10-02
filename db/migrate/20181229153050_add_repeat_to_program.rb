class AddRepeatToProgram < ActiveRecord::Migration[5.2]
  def change
    add_column :programs, :repeat_every, :integer
  end
end
