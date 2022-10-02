class AddLastErrorAtToProgram < ActiveRecord::Migration[6.1]
  def change
    add_column :programs, :last_error_at, :datetime
  end
end
