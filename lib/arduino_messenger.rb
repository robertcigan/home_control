require 'yaml'
require 'socket'

class ArduinoMessenger < EventMachine::Connection
  @@connected_clients = Array.new
  attr_reader :ip, :board, :received_timestamp

  class << self
    def connected_clients
      @@connected_clients
    end
  end

  def post_init
    port, ip = Socket.unpack_sockaddr_in(get_peername)
    @ip = ip
    puts "#{Time.now} #{ip} has connected"
    @received_data_buffer = ""
    @received_timestamp = Time.current
    @largest_data = 0
    @board = Board.where(ip: ip).first
    if @board && !@@connected_clients.collect(&:ip).include?(ip)
      @board.connected!
      @@connected_clients.push(self)
      self.comm_inactivity_timeout = 30

      puts "#{Time.now} #{@board.ip} clients: #{@@connected_clients.collect(&:ip).join(", ")}"
      EventMachine::Timer.new(3) do
        @board.read_values_from_devices
        @board.write_values_to_devices
      end
    elsif @@connected_clients.collect(&:ip).include?(ip)
      puts "#{Time.now} Already connected board #{ip}"
      close_connection
    else
      puts "#{Time.now} Unknow board #{ip}"
      close_connection
    end
  end

  def receive_data(data)
    if @largest_data.nil? || data.size > @largest_data
      @largest_data = data.size
      #if Rails.env.development?
        # puts "#{Time.now} #{@board.ip} Largest data: #{@largest_data}"
        # puts "#{Time.now} #{@board.ip} Buffer: #{data}"
      #end
    end
    @received_data_buffer << data
    # puts "#{Time.now} #{@board.ip} Buffer: #{@received_data_buffer}"
    @received_timestamp = Time.current
    process_buffer
  end

  def process_buffer
    if @received_data_buffer.size > 10e6
      puts "#{Time.now} #{@board.ip} data overflow"
      puts "-------------------------------------"
      puts @received_data_buffer
      puts "-------------------------------------"
      @received_data_buffer = ""
    else
      if @received_data_buffer.ends_with?("\n") || @received_data_buffer.include?("\n")
        begin
          if @received_data_buffer.ends_with?("\n")
            received_jsons = @received_data_buffer.split("\n")
            @received_data_buffer = ""
          else
            received_jsons = @received_data_buffer.split("\n")
            @received_data_buffer = received_jsons.last
            received_jsons = received_jsons[0..-2]
          end
          received_jsons.each do |json_text|
            begin
              json = JSON.parse( json_text )
              if @board
                puts "#{Time.now} #{@board.ip} Parsed #{json_text} from #{ip}"
                @board.parse(json)
              else
                puts "#{Time.now} Parsed #{json_text} from #{ip}"
              end
            rescue JSON::ParserError
              puts "#{Time.now} #{@board.ip} Parse Error - #{json_text}"
              @received_data_buffer = ""
            end
          end
        rescue TypeError
          @received_data_buffer = ""
        end
      end
    end
  end

  def send_command(data)
    send_data(data + "\n")
  end

  def send_data(data)
    puts "#{Time.now} #{@board.ip} Sending: #{data}"
    super(data)
  end

  def unbind
    if @board
      puts "#{Time.now} #{@board.ip} connection closed"
      @board.reload.disconnected!
      @@connected_clients.delete(self)
      puts "#{Time.now} #{@board.ip} clients: #{@@connected_clients.collect(&:ip).join(", ")}"
    else
      puts "#{Time.now} Client #{ip} connection closed"
    end
  end
end
