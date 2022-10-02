class CreateDataLogs < ActiveRecord::Migration[5.0]
  def change
    create_table :data_logs do |t|
      t.references :sensor, foreign_key: true
      t.decimal :value, precision: 6, scale: 2

      t.timestamps
    end
  end
end
