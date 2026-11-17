require 'yaml'
require 'socket'

class ArduinoMessenger < EventMachine::Connection
  MAX_BUFFER_SIZE = 10e6

  @@connected_clients = Array.new
  attr_reader :ip, :board, :received_timestamp

  class << self
    def connected_clients
      @@connected_clients
    end
  end

  # All callbacks below run in the reactor thread: an exception escaping from them would
  # stop EventMachine and with it the whole process, so they log errors instead.
  def post_init
    port, ip = Socket.unpack_sockaddr_in(get_peername)
    @ip = ip
    log "#{Time.now} #{ip} has connected"
    @received_data_buffer = String.new
    @received_timestamp = Time.current
    @largest_data = 0
    @board = Board.where(ip: ip).first
    if @board && !@@connected_clients.collect(&:ip).include?(ip)
      @board.connected!
      @@connected_clients.push(self)
      self.comm_inactivity_timeout = 30

      log "#{Time.now} #{ip} clients: #{@@connected_clients.collect(&:ip).join(", ")}"
      EventMachine::Timer.new(3) do
        safely("initial read/write") do
          @board.read_values_from_devices
          @board.write_values_to_devices
        end
      end
    elsif @@connected_clients.collect(&:ip).include?(ip)
      log "#{Time.now} Already connected board #{ip}"
      close_connection
    else
      log "#{Time.now} Unknow board #{ip}"
      close_connection
    end
  rescue StandardError => e
    log_error("connect", e)
    @@connected_clients.delete(self)
    close_connection
  end

  def receive_data(data)
    if @largest_data.nil? || data.size > @largest_data
      @largest_data = data.size
    end
    @received_data_buffer << data
    @received_timestamp = Time.current
    process_buffer
  end

  # Newline-delimited JSON; a trailing incomplete line stays in the buffer for the next packet.
  def process_buffer
    if @received_data_buffer.size > MAX_BUFFER_SIZE
      log "#{Time.now} #{ip} data overflow"
      log "-------------------------------------"
      log @received_data_buffer
      log "-------------------------------------"
      @received_data_buffer = String.new
    elsif @received_data_buffer.include?("\n")
      lines = @received_data_buffer.split("\n", -1)
      @received_data_buffer = lines.pop || String.new
      lines.each { |json_text| process_line(json_text) }
    end
  end

  def process_line(json_text)
    return if json_text.strip.empty?

    json = JSON.parse(json_text)
    if !json.is_a?(Hash)
      log "#{Time.now} #{ip} Unexpected JSON - #{json_text}"
    elsif @board
      log "#{Time.now} #{ip} Parsed #{json_text} from #{ip}"
      @board.parse(json)
    else
      log "#{Time.now} Parsed #{json_text} from #{ip}"
    end
  rescue JSON::ParserError
    log "#{Time.now} #{ip} Parse Error - #{json_text}"
  rescue StandardError => e
    log_error("processing #{json_text}", e)
  end

  def send_command(data)
    send_data(data + "\n")
  end

  def send_data(data)
    log "#{Time.now} #{ip} Sending: #{data}"
    super(data)
  end

  # Only a connection that was registered as the board's active one may mark the board
  # as disconnected (a rejected duplicate connection from the same IP must not).
  def unbind
    if @@connected_clients.delete(self)
      log "#{Time.now} #{ip} connection closed"
      safely("disconnect") { @board.reload.disconnected! }
      log "#{Time.now} #{ip} clients: #{@@connected_clients.collect(&:ip).join(", ")}"
    else
      log "#{Time.now} Client #{ip} connection closed"
    end
  end

  private

  def safely(action)
    yield
  rescue StandardError => e
    log_error(action, e)
  end

  def log_error(action, error)
    log "#{Time.now} #{ip} ERROR in #{action}: #{error.class}: #{error.message} (#{error.backtrace&.first})"
  end

  def log(message)
    puts message unless Rails.env.test?
  end
end
