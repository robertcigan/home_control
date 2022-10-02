class AddBoardTypeToBoard < ActiveRecord::Migration[6.1]
  def change
    add_column :boards, :board_type, :string, index: true
  end
end
