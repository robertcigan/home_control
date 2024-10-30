require 'dotenv/load'
require 'action_cable_client'
require 'arduino_messenger'
require 'socket'
require 'resolv-replace'

DeviceLog
Device

ip = Socket.ip_address_list.detect{|intf| intf.ipv4_private?}
ip_address = ip ? ip.ip_address : "127.0.0.1"
puts "IP server address detected: #{ip_address}"

client_connected = false
Board.all.each(&:disconnected!)
EventMachine.run do
  Signal.trap("INT")  { EventMachine.stop }
  Signal.trap("TERM") { EventMachine.stop }

  EM.start_server(ip_address, 7777, ArduinoMessenger)
  uri = "ws://#{ENV['HOST']}#{ENV['PORT'] ? ":#{ENV['PORT']}" : ""}/websockets/"
  puts "Websocket server: "
  puts uri
  client = ActionCableClient.new(uri, 'ArduinoChannel')
  
  client.connected do
    client_connected = true
    puts "#{Time.now} successfully connected to Websockets"
  end
  
  client.received do | message |
    if message && message['message']
      # puts "#{Time.now} Sending: #{message["message"]["data"]} to #{message['message']['ip']}"

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
  
  #READ AND WRITE VALUE PERIODICALLY (FALLBACK WHEN SOMETHING FAILS TO WRITE?READ CORRECTLY)
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

  EventMachine::PeriodicTimer.new(5) do
    #check for last received data timestamp
    EM.defer(
      proc do
        begin
          ArduinoMessenger.connected_clients.each do |conn|
            if conn.received_timestamp && (Time.current - conn.received_timestamp) > 30
              puts "#{Time.now} timeout detected to #{conn.board.ip}"
              #conn.board.disconnected!
              conn.close_connection
            end
          end
        ensure 
          ActiveRecord::Base.connection_pool.release_connection
        end
      end
    )
  end

  program_repeated_to_run = false
  EventMachine::PeriodicTimer.new(1) do
    EM.defer(
      proc do
        begin
          unless program_repeated_to_run
            program_repeated_to_run = true
            Program.repeated_to_run.each do |program|
              program.run
            end
          end
        ensure 
          ActiveRecord::Base.connection_pool.release_connection
          program_repeated_to_run = false
        end
      end
    )
  end

  board_modbus_active = false
  EventMachine::PeriodicTimer.new(1) do
    EM.defer(
      proc do
        begin 
          unless board_modbus_active
            board_modbus_active = true
            Board.modbus_tcp.each do |board|
              if board.connected_at.nil? || (Time.current - board.connected_at) > board.data_read_interval.seconds
                #puts "#{Time.now} reading ModBus TCP #{board.name} / #{board.ip}"
                board.read_modbus
              end
            end
          end
        ensure 
          ActiveRecord::Base.connection_pool.release_connection
          board_modbus_active = false            
        end
      end
    )
  end

  device_log_compression = false
  EventMachine::PeriodicTimer.new(30) do
    EM.defer(
      proc do
        begin
          unless device_log_compression
            device_log_compression = true
            Device.for_compression.each do |device|
              if (device.run_compression(true)) 
                #puts "Compressing logs for  #{device.name} - #{device.compression_type_to_human} - #{device.compression_timespan_to_human}"
              end
            end
          end
        ensure 
          ActiveRecord::Base.connection_pool.release_connection
          device_log_compression = false
        end
      end
    )
  end

  EventMachine::PeriodicTimer.new(1.day) do
    EM.defer(
      proc do
        begin
          Device.for_log_clear.each { |device| device.clear_logs }
          Board.for_log_clear.each { |board| board.clear_logs }
        ensure 
          ActiveRecord::Base.connection_pool.release_connection
        end
      end
    )
  end

  periodic_websocket_push = false
  EventMachine::PeriodicTimer.new(60) do
    EM.defer(
      proc do
        begin
          unless periodic_websocket_push
            periodic_websocket_push = true
            Device.repeated_ws_push.each do |device|
              device.push_value_change
              #puts "Manual WS push #{device.name}"
            end
          end
        ensure 
          ActiveRecord::Base.connection_pool.release_connection
          periodic_websocket_push = false
        end
      end
    )
  end
end