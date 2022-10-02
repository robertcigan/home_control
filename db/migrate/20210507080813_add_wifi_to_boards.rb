class AddWifiToBoards < ActiveRecord::Migration[6.1]
  def up
    add_column :boards, :ssid, :string
    add_column :boards, :signal_strength, :integer
    
    add_column :board_logs, :connected, :boolean, default: false, null: false
    
    add_column :board_logs, :signal_strength, :integer
    add_column :board_logs, :ssid, :string

    BoardLog.reset_column_information

    BoardLog.where(log_type: "connected").update_all(connected: true)
    BoardLog.where(log_type: "disconnected").update_all(connected: false)
    
    remove_column :board_logs, :log_type
  end


  def down
    add_column :board_logs, :log_type, :string
    BoardLog.reset_column_information
    BoardLog.where(connected: true).update_all(log_type: "connected")
    BoardLog.where(connected: false).update_all(log_type: "disconnected")

    remove_column :boards, :ssid, :string
    remove_column :boards, :signal_strength, :integer
    
    remove_column :board_logs, :connected, :boolean, default: false, null: false
    
    remove_column :board_logs, :signal_strength, :integer
    remove_column :board_logs, :ssid, :string
  end
end
