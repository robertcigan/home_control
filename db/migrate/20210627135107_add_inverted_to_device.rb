class AddInvertedToDevice < ActiveRecord::Migration[6.1]
  def change
    add_column :devices, :inverted, :boolean, default: false, null: false
    add_column :devices, :poll, :integer
  end
end
