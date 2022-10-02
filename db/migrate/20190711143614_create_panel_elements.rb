class CreatePanelElements < ActiveRecord::Migration[5.2]
  def change
    create_table :panel_elements do |t|
      t.string :name
      t.integer :panel_id
      t.string :element_type
      t.integer :device_id
      t.integer :program_id
      t.integer :position_x
      t.integer :position_y

      t.timestamps
    end
    
    add_index :panel_elements, :name
    add_index :panel_elements, :panel_id
    add_index :panel_elements, :device_id
    add_index :panel_elements, :program_id
  end
end
