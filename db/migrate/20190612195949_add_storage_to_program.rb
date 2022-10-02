class AddStorageToProgram < ActiveRecord::Migration[5.2]
  def change
    add_column :programs, :storage, :text
  end
end
