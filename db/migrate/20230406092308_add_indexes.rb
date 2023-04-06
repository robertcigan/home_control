class AddIndexes < ActiveRecord::Migration[7.0]
  def change
    add_index :device_logs, :created_at
    add_index :device_logs, :updated_at

    add_index :board_logs, :created_at
    add_index :board_logs, :updated_at

    add_index :boards, :name
    add_index :boards, :board_type
    add_index :boards, :data_read_interval

    add_index :devices, :last_change
    add_index :devices, :board_id
    add_index :devices, :type
    add_index :devices, :name
    add_index :devices, :compression_last_run_at

    add_index :panels, :created_at

    add_index :programs, :created_at
    add_index :programs, :enabled
    add_index :programs, :last_error_at
    add_index :programs, :last_run
    add_index :programs, :updated_at

    add_index :programs_devices, :trigger
    add_index :programs_devices, :variable_name

    add_index :widgets, :show_updated
    add_index :widgets, :created_at
    add_index :widgets, :updated_at
    add_index :widgets, :name
  end
end
