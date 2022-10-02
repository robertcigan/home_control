class CreateProgramsSensors < ActiveRecord::Migration[5.0]
  def change
    create_table :programs_sensors do |t|
      t.integer :program_id
      t.integer :sensor_id
      t.string :variable_name

      t.timestamps
    end
    
    add_index :programs_sensors, :program_id
    add_index :programs_sensors, :sensor_id
    add_index :programs_sensors, :variable_name
  end
end
