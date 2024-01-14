class AddLogClearingToDeviceLogs < ActiveRecord::Migration[7.0]
  def change
    add_column :devices, :days_to_preserve_logs, :integer
    add_index :devices, :days_to_preserve_logs

    add_column :boards, :days_to_preserve_logs, :integer
    add_index :boards, :days_to_preserve_logs
  end
end
