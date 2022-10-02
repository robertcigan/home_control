class AddColsToPanelElement < ActiveRecord::Migration[5.2]
  def change
    add_column :panel_elements, :element_class, :string
  end
end
