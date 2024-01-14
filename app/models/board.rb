class Board < ApplicationRecord
  include WebsocketPushChange
  include AttributeOption
  attribute_options :board_type, [:arduino_mega_8b, :esp8266_bat, :modbus_tcp]
  
  validates :name, :ip, presence: true, uniqueness: { unless: :board_type_modbus_tcp? }
  validates :board_type, presence: true
  validates :slave_address, :data_read_interval, presence: true, if: :board_type_modbus_tcp?

  has_many :devices, dependent: :restrict_with_error
  has_many :board_logs, dependent: :delete_all

  scope :ip, proc { |data| where(ip: data) }
  scope :modbus_tcp, proc { where(board_type: Board::BoardType::MODBUS_TCP) }
  scope :for_log_clear,  proc { where.not(days_to_preserve_logs: nil) }

  before_save :log_board_log

  def to_s
    name.present? ? name : "UNKNOWN"
  end

  def ping
    send_to_arduino({ ping: true })
  end

  def connected?
    !connected_at.nil? && (connected_at > (Time.current - 25.seconds))
  end
  
  def connected; connected?; end

  def disconnected!
    update!(connected_at: nil, ssid: nil, signal_strength: nil)
  end

  def connected!(params = {})
    update!({ connected_at: Time.current }.merge(params))
  end

  def parse(data) # incoming json
    case data.keys.first
    when "pong"
      connected!(version: data["version"], ssid: data["ssid"], signal_strength: data["rssi"])
    when "send_devices"
      set_pins
    when "device"
      if data["device"] && data["device"]["id"]
        device = devices.find_by(id: data["device"]["id"])
        if device
          if data["device"]["value"] != nil
            device.set(data["device"]["value"])
          elsif device.is_a?(Device::Button)
            device.set()
          end
        else
          puts "RECEIVED WRONG DEVICE DATA: " + data.to_s
        end
      else
        puts "RECEIVED WRONG DATA: " + data.to_s
      end
    else
      puts "RECEIVED WRONG JSON: " + data.to_s
    end
  end
  
  def json_data
    super.merge(status: connected.to_s, ssid: ssid, "signal-strength": signal_strength)
  end
  
  def send_to_arduino(data)
    ActionCable.server.broadcast("arduino", { ip: ip, data: data.to_json } )
  end

  def set_pins
    send_to_arduino({ reset_devices: true })
    # send devices pin assignments
    devices.each do |device|
      if device.respond_to?(:setup_pin)
        device.setup_pin
      end
    end
  end

  def read_values_from_devices
    devices.reload.select{|device| device.readable_value? }.each do |device|
      device.get_value_from_arduino
    end
  end

  def write_values_to_devices
    devices.reload.select{|device| device.writable_value? }.each do |device|
      device.set_value_to_arduino 
    end
  end

  def chart_data_status
    connected_at.nil? ? 0 : 1
  end

  def chart_data_ssid
    ssid
  end

  def chart_data_signal_strength
    signal_strength ? (signal_strength / 100.0) : nil
  end

  def read_modbus # group by consecutive address blocks
    devices_to_read = devices.where.not(holding_register_address: nil).order(:holding_register_address).load
    device_blocks = []
    single_block = []
    devices_to_read.each_with_index do |device, i|
      if i == 0
        single_block << device
      else
        if device.holding_register_address == devices_to_read[i - 1].holding_register_address + 1
          single_block << device
        else
          device_blocks << single_block
          single_block = [device]
        end
      end
    end
    if single_block.any?
      device_blocks << single_block
    end
    device_blocks.each do |device_block|
      read_modbus_block(device_block)
    end
  end

  def read_modbus_block(device_block)
    begin
      #puts "#{Time.now} Reading Modbus started - #{name} / #{ip}"
      ModBus::TCPClient.connect(ip, 502) do |cl|
        cl.read_retry_timeout = 1
        cl.read_retries = 1
        cl.with_slave(slave_address) do |slave|
          slave.debug = false
          begin
            regs = slave.read_holding_registers(device_block.first.holding_register_address, device_block.size)
            regs.each_with_index do |reg, i|
              if device_block[i].modbus_data_type_int16?
                reg_val = reg > 32767 ?  reg - 65536 : reg
              else
                reg_val = reg
              end
              device_block[i].set(device_block[i].scale ? (reg_val/ device_block[i].scale.to_f) : reg_val)
            end
          end
        end
      end
      #puts "#{Time.now} Reading Modbus ended - #{name} / #{ip}"
      connected!
    rescue ModBus::Errors::ModBusException, Errno::EHOSTUNREACH, Errno::ENETUNREACH, Errno::EHOSTDOWN, Errno::ECONNREFUSED => e
      puts "#{Time.now} Modbus Error - #{name} / #{ip} - #{e.message}"
      disconnected!
    end
  end
  
  def clear_logs
    logs_to_clear = board_logs.where("created_at < ?", Time.current - days_to_preserve_logs.days)
    logs_to_clear.delete_all
  end

  private

  def log_board_log
    if connected_at_changed? || signal_strength_changed? || ssid_changed?
      last_board_log = board_logs.order(:id).last
      connected_status = !connected_at.nil?

      if last_board_log.nil? || (last_board_log.connected != connected_status || ssid != last_board_log.ssid || signal_strength != last_board_log.signal_strength)
        board_logs.build(connected: !connected_at.nil?, ssid: ssid, signal_strength: signal_strength)
      end
    end
  end
end