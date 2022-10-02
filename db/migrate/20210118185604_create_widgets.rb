class CreateWidgets < ActiveRecord::Migration[6.1]
  def change
    create_table :widgets do |t|
      t.integer :panel_id, null: false
      t.string :widget_type
      t.integer :device_id
      t.integer :program_id
      t.integer :x
      t.integer :y
      t.integer :w
      t.integer :h

      t.timestamps
    end

    add_index :widgets, :panel_id
    add_index :widgets, :device_id
    add_index :widgets, :program_id

    drop_table :panel_elements do |t|
      t.string "name"
      t.integer "panel_id"
      t.string "element_type"
      t.integer "device_id"
      t.integer "program_id"
      t.integer "position_x"
      t.integer "position_y"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "element_class"
      t.index ["device_id"], name: "index_panel_elements_on_device_id"
      t.index ["name"], name: "index_panel_elements_on_name"
      t.index ["panel_id"], name: "index_panel_elements_on_panel_id"
      t.index ["program_id"], name: "index_panel_elements_on_program_id"
    end
  end
end
