class CreateDevices < ActiveRecord::Migration[5.0]
  def change
    create_table :devices do |t|
      t.string :name
      t.string :device_type, index: true
      t.integer :pin, index: true

      t.timestamps
    end
  end
end
