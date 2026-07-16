require 'dotenv/load'
require 'action_cable_client'
require 'arduino_messenger'
require 'socket'
require 'resolv-replace'

class ArduinoServer
  class << self
    def handle_arduino_boards(uri)
      start_action_cable_client(uri, "ArduinoChannel") do |message|
        if message && message["message"]
          if (found_connected_client = ArduinoMessenger.connected_clients.find { |c| c.ip == message["message"]["ip"] })
            found_connected_client.send_command(message["message"]["data"])
          else
            puts "#{Time.now} Command not sent! No connection to Arduino!"
          end
        end
      end
    end

    def handle_modbus_boards(uri)
      start_action_cable_client(uri, "ModbusChannel") do |message|
        if message && message["message"]
          EM.defer(
            proc do
              begin
                Device.uncached do
                  device = Device.where(id: message["message"]["device_id"]).first
                  if device
                    device.board.write_modbus(device)
                  else
                    puts "Device not found: #{message["message"]["device_id"]}"
                  end
                end
              ensure
                ActiveRecord::Base.connection_pool.release_connection
              end
            end
          )
        end
      end
    end

    # Fresh connect instead of gem reconnect! (that only reopens TCP and breaks WS handshake).
    def start_action_cable_client(uri, channel, &on_message)
      state = { connected: false, client: nil }

      open_client = lambda do
        if state[:client]
          begin
            state[:client]._websocket_client.close
          rescue StandardError
          end
          state[:client] = nil
        end

        client = ActionCableClient.new(uri, channel, false)
        state[:client] = client
        state[:connected] = false

        client.connected do
          state[:connected] = true
          puts "#{Time.now} successfully connected to Websockets (#{channel})"
        end

        client.disconnected do
          state[:connected] = false
          puts "#{Time.now} disconnected from Websockets (#{channel})"
        end

        client.connect!

        client.errored do |message|
          puts "#{Time.now} ERROR (#{channel}): #{message}"
        end

        client.received do |message|
          on_message.call(message)
        end
      end

      open_client.call

      EventMachine::PeriodicTimer.new(10) do
        if !state[:connected]
          puts "#{Time.now} reconnecting Websockets (#{channel})..."
          open_client.call
        end
      end
    end

    def ping_boards
      EventMachine::PeriodicTimer.new(10) do
        EM.defer(
          proc do
            ArduinoMessenger.connected_clients.each do |conn|
              conn.board.ping
            end
          end
        )
      end
    end

    def read_write_boards
      read_write_arduino_boards_active = false
      read_write_modbus_boards_active = false
      EventMachine::PeriodicTimer.new(60) do
        EM.defer(
          proc do
            begin
              unless read_write_arduino_boards_active
                read_write_arduino_boards_active = true
                ArduinoMessenger.connected_clients.each do |conn|
                  conn.board.read_values_from_devices
                  conn.board.write_values_to_devices
                end
              end
            ensure
              ActiveRecord::Base.connection_pool.release_connection
              read_write_arduino_boards_active = false
            end
          end
        )
        EM.defer(
          proc do
            begin
              unless read_write_modbus_boards_active
                read_write_modbus_boards_active = true
                Board.modbus_tcp.each do |board|
                  board.write_values_to_devices
                end
              end
            ensure
              ActiveRecord::Base.connection_pool.release_connection
              read_write_modbus_boards_active = false
            end
          end
        )
      end
    end

    def detect_disconnected_boards
      EventMachine::PeriodicTimer.new(5) do
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
    end

    def run_programs
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
    end

    def read_modbus_boards
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
    end

    def compress_device_logs
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
    end

    def clear_logs
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
    end

    def push_device_values
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


    # Prefer explicit ACTION_CABLE_URL from Procfile; fall back to HOST/PORT.
    # Use 127.0.0.1 (not localhost) to avoid IPv6 (::1) mismatch with Puma.
    # No trailing slash — some WS clients fail on /websockets/ → /websockets redirects.
    def websocket_uri
      configured = ENV["ACTION_CABLE_URL"].to_s
      if !configured.empty?
        configured.sub(%r{/\z}, "")
      else
        host = ENV.fetch("HOST", "127.0.0.1")
        if host == "localhost"
          host = "127.0.0.1"
        end
        port = ENV.fetch("PORT", "3000")
        "ws://#{host}:#{port}/websockets"
      end
    end

    def run
      ip = Socket.ip_address_list.detect{|intf| intf.ipv4_private?}
      ip_address = ip ? ip.ip_address : "127.0.0.1"
      puts "IP server address detected: #{ip_address}"

      Board.all.each(&:disconnected!)
      EventMachine.run do
        Signal.trap("INT")  { EventMachine.stop }
        Signal.trap("TERM") { EventMachine.stop }

        EM.start_server(ip_address, 7777, ArduinoMessenger)
        uri = websocket_uri
        puts "Websocket server: #{uri}"
        puts "ENV PORT=#{ENV["PORT"].inspect} HOST=#{ENV["HOST"].inspect}"

        handle_arduino_boards(uri)
        handle_modbus_boards(uri)
        ping_boards
        read_write_boards
        detect_disconnected_boards
        run_programs
        read_modbus_boards
        compress_device_logs
        clear_logs
        push_device_values
      end
    end
  end
end