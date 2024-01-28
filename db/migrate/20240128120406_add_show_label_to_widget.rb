class AddShowLabelToWidget < ActiveRecord::Migration[7.0]
  def change
    add_column :widgets, :show_label, :boolean, default: true, null: false
    add_index :widgets, :show_label
  end
end
