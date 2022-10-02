class AddLogsCompressionToDevice < ActiveRecord::Migration[6.1]
  def change
    add_column :devices, :compression_type, :string, index: true
    add_column :devices, :compression_timespan, :string, index: true
    add_column :devices, :compression_backlog, :integer, index: true
    add_column :devices, :compression_last_run_at, :datetime
  end
end
