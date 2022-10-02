class AddStylesToWidget < ActiveRecord::Migration[6.1]
  def change
    add_column :widgets, :color_1, :string
    add_column :widgets, :color_2, :string
    add_column :widgets, :icon, :string
    add_column :widgets, :name, :string
  end
end
