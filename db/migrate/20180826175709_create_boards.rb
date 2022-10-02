class CreateBoards < ActiveRecord::Migration[5.2]
  def change
    create_table :boards do |t|
      t.string :ip
      t.string :name
      t.boolean :connected, default: false, null: false
      t.timestamps
    end

    add_index :boards, :ip

    add_column :sensors, :board_id, :integer, index: true
    add_column :devices, :board_id, :integer, index: true
  end
end
