class ChangeConnectedToConnectedAt < ActiveRecord::Migration[5.2]
  def change
    remove_column :boards, :connected
    add_column :boards, :connected_at, :datetime
    add_index :boards, :connected_at
  end
end
