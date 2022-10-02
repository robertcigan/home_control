class AddTypeToDevice < ActiveRecord::Migration[5.2]
  def change
    remove_column :devices, :value, :decimal

    add_column :devices, :type, :string, index: true
    add_column :devices, :value_integer, :integer
    add_column :devices, :value_boolean, :boolean
    add_column :devices, :value_string, :string
    add_column :devices, :value_decimal, :decimal, precision: 6, scale: 2
  end
end
