class AddWidthHeightToPanel < ActiveRecord::Migration[6.1]
  def change
    add_column :panels, :row, :integer
    add_column :panels, :column, :integer
  end
end
