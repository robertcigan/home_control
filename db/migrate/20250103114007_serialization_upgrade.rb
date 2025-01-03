class SerializationUpgrade < ActiveRecord::Migration[7.1]
  def up
    Program.all.each{|p| p.update_column(:storage, {})}
  end

  def down
  end
end
