require 'dotenv/load'
require 'action_cable_client'
require 'arduino_messenger'
require 'socket'
require 'resolv-replace'

class ArduinoServer
  CONNECTION_TIMEOUT = 30 # seconds without data from a board before its connection is closed
  CLEAR_LOGS_FIRST_RUN_DELAY = 60 # seconds after start, then once a day

  class << self
    def handle_arduino_boards(uri)
      start_action_cable_client(uri, "ArduinoChannel") do |message|
        dispatch_arduino_command(message)
      end
    end

    # Runs in the reactor thread (called from the Action Cable client callback).
    def dispatch_arduino_command(message)
      payload = message.is_a?(Hash) ? message["message"] : nil
      return unless payload.is_a?(Hash)

      if (found_connected_client = ArduinoMessenger.connected_clients.find { |c| c.ip == payload["ip"] })
        found_connected_client.send_command(payload["data"])
      else
        log "#{Time.now} Command not sent! No connection to Arduino!"
      end
    end

    def handle_modbus_boards(uri)
      start_action_cable_client(uri, "ModbusChannel") do |message|
        if message.is_a?(Hash) && message["message"]
          EM.defer(
            proc do
              begin
                safely("modbus write") { write_modbus_device(message["message"]["device_id"]) }
              ensure
                ActiveRecord::Base.connection_pool.release_connection
              end
            end
          )
        end
      end
    end

    def write_modbus_device(device_id)
      Device.uncached do
        device = Device.where(id: device_id).first
        if device
          device.board.write_modbus(device)
        else
          log "Device not found: #{device_id}"
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
          log "#{Time.now} successfully connected to Websockets (#{channel})"
        end

        client.disconnected do
          state[:connected] = false
          log "#{Time.now} disconnected from Websockets (#{channel})"
        end

        client.connect!

        client.errored do |message|
          log "#{Time.now} ERROR (#{channel}): #{message}"
        end

        client.received do |message|
          safely("#{channel} message") { on_message.call(message) }
        end
      end

      open_client.call

      EventMachine::PeriodicTimer.new(10) do
        if !state[:connected]
          log "#{Time.now} reconnecting Websockets (#{channel})..."
          safely("#{channel} reconnect") { open_client.call }
        end
      end
    end

    def ping_boards
      every(10, "ping boards") do
        each_safely(ArduinoMessenger.connected_clients.dup, "ping") do |conn|
          conn.board.ping
        end
      end
    end

    def read_write_boards
      every(60, "read/write Arduino boards") do
        each_safely(ArduinoMessenger.connected_clients.dup, "read/write Arduino board") do |conn|
          conn.board.read_values_from_devices
          conn.board.write_values_to_devices
        end
      end
      every(60, "write Modbus boards") do
        each_safely(Board.modbus_tcp, "write Modbus board") do |board|
          board.write_values_to_devices
        end
      end
    end

    # Runs in the reactor thread: EventMachine connections must not be closed from pool threads.
    def detect_disconnected_boards
      every(5, "detect disconnected boards", defer: false) do
        close_timed_out_connections
      end
    end

    def close_timed_out_connections
      ArduinoMessenger.connected_clients.dup.each do |conn|
        if conn.received_timestamp && (Time.current - conn.received_timestamp) > CONNECTION_TIMEOUT
          log "#{Time.now} timeout detected to #{conn.ip}"
          conn.close_connection
        end
      end
    end

    def run_programs
      every(1, "run programs") do
        each_safely(Program.repeated_to_run, "program") do |program|
          program.run
        end
      end
    end

    def read_modbus_boards
      every(1, "read Modbus boards") do
        each_safely(Board.modbus_tcp, "read Modbus board") do |board|
          if board.connected_at.nil? || (Time.current - board.connected_at) > board.data_read_interval.seconds
            board.read_modbus
          end
        end
      end
    end

    def compress_device_logs
      every(30, "compress device logs") do
        each_safely(Device.for_compression, "compress device logs") do |device|
          device.run_compression(true)
        end
      end
    end

    def clear_logs
      tick = every(1.day, "clear logs") do
        each_safely(Device.for_log_clear, "clear device logs") { |device| device.clear_logs }
        each_safely(Board.for_log_clear, "clear board logs") { |board| board.clear_logs }
      end
      EventMachine::Timer.new(CLEAR_LOGS_FIRST_RUN_DELAY) { tick.call }
    end

    def push_device_values
      every(60, "push device values") do
        each_safely(Device.repeated_ws_push, "push device value") do |device|
          device.push_value_change
        end
      end
    end

    # Schedules a periodic job. A run is skipped while the previous run of the same job
    # is still in progress, and any error is logged instead of killing the process.
    # By default the job runs in the EventMachine thread pool; defer: false keeps it
    # in the reactor thread (only for short jobs that touch EM connections).
    # Returns the tick callable so the caller can also trigger a run manually.
    def every(interval, name, defer: true, &job)
      lock = Mutex.new
      tick = lambda do
        next if lock.locked?

        if defer
          EM.defer(proc { run_exclusively(name, lock, release_db_connection: true, &job) })
        else
          run_exclusively(name, lock, &job)
        end
      end
      EventMachine::PeriodicTimer.new(interval, tick)
      tick
    end

    def run_exclusively(name, lock, release_db_connection: false, &job)
      return false unless lock.try_lock

      begin
        safely(name, &job)
      ensure
        lock.unlock
        ActiveRecord::Base.connection_pool.release_connection if release_db_connection
      end
      true
    end

    # One failing record must not stop processing of the remaining ones.
    def each_safely(records, name)
      records.each do |record|
        safely(name) { yield record }
      end
    end

    def safely(name)
      yield
    rescue StandardError => e
      log "#{Time.now} ERROR in #{name}: #{e.class}: #{e.message} (#{e.backtrace&.first})"
      nil
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
      log "IP server address detected: #{ip_address}"

      Board.all.each(&:disconnected!)
      EventMachine.run do
        Signal.trap("INT")  { EventMachine.stop }
        Signal.trap("TERM") { EventMachine.stop }

        EM.start_server(ip_address, 7777, ArduinoMessenger)
        uri = websocket_uri
        log "Websocket server: #{uri}"
        log "ENV PORT=#{ENV["PORT"].inspect} HOST=#{ENV["HOST"].inspect}"

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

    private

    def log(message)
      puts message unless Rails.env.test?
    end
  end
end
