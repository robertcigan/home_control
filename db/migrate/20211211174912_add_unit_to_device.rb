class AddUnitToDevice < ActiveRecord::Migration[6.1]
  def change
    add_column :devices, :unit, :string
  end
end
