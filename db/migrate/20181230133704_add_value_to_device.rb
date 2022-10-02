class AddValueToDevice < ActiveRecord::Migration[5.2]
  def change
    add_column :devices, :value, :decimal, precision: 6, scale: 2
    remove_column :programs_devices, :sound_volume, :integer
    remove_column :programs_devices, :sound_directory, :integer
    remove_column :programs_devices, :sound_file, :integer
  end
end
