class DropTableSensors < ActiveRecord::Migration[5.2]
  def change
    drop_table :data_logs
    drop_table :sensors
    drop_table :programs_sensors
    
    create_table :device_logs do |t|
      t.integer :device_id, index: true
      t.decimal :value, precision: 6, scale: 2
      t.timestamps
    end
  end
end
