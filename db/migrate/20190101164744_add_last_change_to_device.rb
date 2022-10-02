class AddLastChangeToDevice < ActiveRecord::Migration[5.2]
  def change
    add_column :devices, :last_change, :datetime
  end
end
