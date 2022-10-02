class CreateBoardLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :board_logs do |t|
      t.integer :board_id
      t.string :log_type

      t.timestamps
    end
    add_index :board_logs, :log_type
  end
end
