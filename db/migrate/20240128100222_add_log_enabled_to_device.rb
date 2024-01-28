class AddLogEnabledToDevice < ActiveRecord::Migration[7.0]
  def change
    add_column :devices, :log_enabled, :boolean, default: true, null: false
    add_index :devices, :log_enabled
  end
end
