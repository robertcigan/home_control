class AddSoundVolumeAndSoundFileToProgram < ActiveRecord::Migration[5.0]
  def change
    add_column :programs, :sound_volume, :integer
    add_column :programs, :sound_directory, :integer
    add_column :programs, :sound_file, :integer
  end
end
