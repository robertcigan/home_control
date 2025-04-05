class AddModbusWritableToDevices < ActiveRecord::Migration[7.1]
  def change
    add_column :devices, :virtual_writable, :boolean, default: false, null: false
    add_index :devices, :virtual_writable
  end
end
