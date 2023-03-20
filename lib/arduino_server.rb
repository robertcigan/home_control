require 'action_cable_client'
require 'arduino_messenger'
require 'socket'
require 'resolv-replace'

DeviceLog
Device

ip = Socket.ip_address_list.detect{|intf| intf.ipv4_private?}
ip_address = ip.ip_address
puts "IP server address detected: #{ip_address}"

client_connected = false
Board.all.each(&:disconnected!)
EventMachine.run do
  Signal.trap("INT")  { EventMachine.stop }
  Signal.trap("TERM") { EventMachine.stop }

  EM.start_server(ip_address, 7777, ArduinoMessenger)

  uri = "ws://#{ENV['WEBSOCKET_HOST']}#{ENV['WEBSOCKET_PORT'] ? ":#{ENV['WEBSOCKET_PORT']}" : ""}/websockets/"
  puts uri
  client = ActionCableClient.new(uri, 'ArduinoChannel')
  
  client.connected do
    client_connected = true
    puts "#{Time.now} successfully connected to Websockets"
  end
  
  client.received do | message |
    if message && message['message']
      puts "#{Time.now} Sending: #{message["message"]["data"]} to #{message['message']['ip']}"

      if (found_connected_client = ArduinoMessenger.connected_clients.find { |c| c.ip == message['message']['ip'] })
        found_connected_client.send_command(message["message"]["data"])
      else
        puts "#{Time.now} Command not sent! No connection to Arduino!"
      end
    end
  end

  client.errored do |message|
    puts "#{Time.now} ERROR: " + message
    #EventMachine::stop_event_loop
  end

  client.disconnected do
    client_connected = false
    puts "#{Time.now} disconnected from Websockets"
  end

  # PING PONG
  EventMachine::PeriodicTimer.new(10) do
    #websockets connection reconnect
    unless client_connected
      client.reconnect!
    end
    #arduinos connection
    ArduinoMessenger.connected_clients.each do |conn|
      conn.board.ping
    end
  end
  
  #READ AND WRITE VALUE PERIODICALLY (FALLBACK WHEN SOMETHING FAILS TO WRITE?READ)
  EventMachine::PeriodicTimer.new(60) do
    EM.defer(
      proc do
        begin
          ArduinoMessenger.connected_clients.each do |conn| 
            conn.board.read_values_from_devices
            conn.board.write_values_to_devices
          end
        ensure 
          ActiveRecord::Base.connection_pool.release_connection
        end
      end
    )
  end

  EventMachine::PeriodicTimer.new(3) do
    #check for last received data timestamp
    EM.defer(
      proc do
        begin
          ArduinoMessenger.connected_clients.each do |conn|
            if conn.received_timestamp && (Time.current - conn.received_timestamp) > 20
              puts "#{Time.now} timeout detected to #{conn.board.ip}"
              conn.board.disconnected!
              conn.close_connection
            end
          end
        ensure 
          ActiveRecord::Base.connection_pool.release_connection
        end
      end
    )
  end

  EventMachine::PeriodicTimer.new(1) do
    EM.defer(
      proc do
        begin 
          Board.where(board_type: Board::BoardType::MODBUS_TCP).each do |board|
            if board.connected_at.nil? || (Time.current - board.connected_at) > board.data_read_interval.seconds
              puts "#{Time.now} reading ModBus TCP #{board.name} / #{board.ip}"
              board.read_modbus
            end
          end
          Program.repeated_to_run.each do |program|
            program.run
          end
        ensure 
          ActiveRecord::Base.connection_pool.release_connection
        end
      end
    )
  end

  EventMachine::PeriodicTimer.new(20) do
    EM.defer(
      proc do
        begin 
          Device.where.not(compression_type: nil).where.not(compression_type: "").each do |device|
            if (device.run_compression(true)) 
              puts "Compressing logs for  #{device.name} - #{device.compression_type_to_human} - #{device.compression_timespan_to_human}"
            end
          end
        ensure 
          ActiveRecord::Base.connection_pool.release_connection
        end
      end
    )
  end
end