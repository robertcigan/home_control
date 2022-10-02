class AddShowUpdatedToWidget < ActiveRecord::Migration[6.1]
  def change
    add_column :widgets, :show_updated, :boolean, default: false, null: false
    change_column_default :panels, :row, from: nil, to: 12
    change_column_default :panels, :column, from: nil, to: 12
  end
end
