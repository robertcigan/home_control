class AddSoundSettingsToProgramsDevice < ActiveRecord::Migration[5.2]
  def change
    add_column :programs_devices, :sound_volume, :integer
    add_column :programs_devices, :sound_directory, :integer
    add_column :programs_devices, :sound_file, :integer
    
    remove_column :programs, :sound_volume, :integer
    remove_column :programs, :sound_directory, :integer
    remove_column :programs, :sound_file, :integer
  end
end
