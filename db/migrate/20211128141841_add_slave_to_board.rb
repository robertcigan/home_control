class AddSlaveToBoard < ActiveRecord::Migration[6.1]
  def change
    add_column :boards, :slave_address, :integer, index: true
    add_column :boards, :data_read_interval, :integer
    add_column :devices, :holding_register_address, :integer, index: true
    add_column :devices, :scale, :integer
  end
end
