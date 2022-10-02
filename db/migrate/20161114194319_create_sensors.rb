class CreateSensors < ActiveRecord::Migration[5.0]
  def change
    create_table :sensors do |t|
      t.string :name
      t.string :device_type, index: true
      t.decimal :value, precision: 6, scale: 2
      t.integer :pin, index: true

      t.timestamps
    end
  end
end
