class AddModbusDataTypeToDevice < ActiveRecord::Migration[6.1]
  def change
    add_column :devices, :modbus_data_type, :string
  end
end
