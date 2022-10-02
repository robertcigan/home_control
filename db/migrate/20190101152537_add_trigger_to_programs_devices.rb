class AddTriggerToProgramsDevices < ActiveRecord::Migration[5.2]
  def change
    add_column :programs_devices, :trigger, :boolean, default: false, null: false
  end
end
