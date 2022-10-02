class CreatePanels < ActiveRecord::Migration[5.2]
  def change
    create_table :panels do |t|
      t.string :name

      t.timestamps
    end
    add_index :panels, :name
  end
end
