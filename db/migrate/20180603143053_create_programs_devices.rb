class CreateProgramsDevices < ActiveRecord::Migration[5.0]
  def change
    create_table :programs_devices do |t|
      t.integer :program_id
      t.integer :device_id
      t.string :variable_name

      t.timestamps
    end
    
    add_index :programs_devices, :program_id
    add_index :programs_devices, :device_id
    add_index :programs_devices, :variable_name
  end
end
