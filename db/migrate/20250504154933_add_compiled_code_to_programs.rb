class AddCompiledCodeToPrograms < ActiveRecord::Migration[7.1]
  def up
    add_column :programs, :compiled_code, :text
    add_column :programs, :output, :text

    Program.reset_column_information
    puts "Compiling programs..."
    Program.find_each do |program|
      puts "Compiling program #{program.id}"
      program.save!
    end
  end

  def down
    remove_column :programs, :compiled_code
    remove_column :programs, :output
  end
end
