class AddVersionToBoard < ActiveRecord::Migration[6.1]
  def change
    add_column :boards, :version, :integer
    add_index :boards, :version
  end
end
