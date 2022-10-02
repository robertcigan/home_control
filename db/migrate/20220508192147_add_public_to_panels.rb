class AddPublicToPanels < ActiveRecord::Migration[6.1]
  def change
    add_column :panels, :public_access, :boolean, default: false, null: false
  end
end
