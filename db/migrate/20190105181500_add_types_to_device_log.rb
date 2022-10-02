class AddTypesToDeviceLog < ActiveRecord::Migration[5.2]
  def change
    remove_column :device_logs, :value, :decimal
    
    add_column :device_logs, :value_integer, :integer
    add_column :device_logs, :value_boolean, :boolean
    add_column :device_logs, :value_string, :string
    add_column :device_logs, :value_decimal, :decimal, precision: 6, scale: 2
  end
end
