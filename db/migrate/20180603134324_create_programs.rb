class CreatePrograms < ActiveRecord::Migration[5.0]
  def change
    create_table :programs do |t|
      t.string :name
      t.string :program_type
      t.string :code

      t.timestamps
    end
    
    add_index :programs, :program_type
  end
end
