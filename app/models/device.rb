class Device < ApplicationRecord
  GET_VALUE = "!"
  self.inheritance_column = :device_type
  include AttributeOption

  def self.device_types_to_collection
    I18n.t("activerecord.attribute_options.device.device_type").to_a.map{|i| [i.last, "Device::#{i.first.to_s.camelize}"] }
  end
  
  def device_type_to_human
    I18n.t("activerecord.attribute_options.device.device_type.#{device_type.sub("Device::", "").underscore}") if device_type.present?
  end
  
  I18n.t("activerecord.attribute_options.device.device_type").each do |option, name|
    scope "device_type_#{option.to_s}".to_sym, -> { where(device_type: "Device::#{option.to_s.camelize}") }

    define_method "device_type_#{option.to_s}?" do
      device_type == "Device::#{option.to_s.camelize}"
    end
  end

  attribute_options :modbus_data_type, [:uint16, :int16]
  def modbus_data_type_to_human
    I18n.t("activerecord.attribute_options.device.modbus_data_type.#{modbus_data_type}") if modbus_data_type.present?
  end
  attribute_options :compression_type, [:average, :w_average, :end_value, :max_value]
  def compression_type_to_human
    I18n.t("activerecord.attribute_options.device.compression_type.#{compression_type}") if compression_type.present?
  end
  attribute_options :compression_timespan, [:min1, :min5, :min10, :hour, :day]
  def compression_timespan_to_human
    I18n.t("activerecord.attribute_options.device.compression_timespan.#{compression_timespan}") if compression_timespan.present?
  end

  include WebsocketPushChange
  include LogCompression
  
  validates :name, :device_type, presence: true
  validates :pin, uniqueness: { scope: :board_id, allow_nil: true }
  validates :holding_register_address, presence: true, if: -> (device) { device.board && device.board.board_type_modbus_tcp? }
  validates :compression_timespan, :compression_backlog, presence: { if:  proc { |device| device.compression_type.present? } }
  
  has_many :device_logs, dependent: :delete_all
  has_many :programs_devices, dependent: :destroy
  has_many :programs, through: :programs_devices
  has_many :widgets, dependent: :destroy
  
  belongs_to :board, optional: true

  scope :board, proc { |data| joins(:board).where(boards: { ip: data }) }
  scope :repeated_ws_push, proc { joins(:widgets).distinct.where("devices.updated_at < ?", Time.current - 60.seconds) }
  scope :for_compression, proc { where(log_enabled: true).where.not(compression_type: nil).where.not(compression_type: "") }
  scope :for_log_clear,  proc { where.not(days_to_preserve_logs: nil) }

  before_save :log_device_log, if: :log_enabled?
  after_save :detect_log_enabled_change
  after_create :reset_pins
  after_destroy :reset_pins
  after_update :detect_hw_change

  def to_s
    name.present? ? name : "UNKNOWN"
  end

  def last_change_text
    last_change ? I18n.l(last_change, format: :custom) : nil
  end

  def json_data
    super.merge(status: status.to_s, updated: last_change_text, value: value.to_s, indication: indication.to_s)
  end
  
  def status
    nil
  end
  
  def readable_value?
    false
  end
  
  def writable_value?
    false
  end
  
  def toggle?
    false
  end

  def poll?
    false
  end
  
  def indication
    unit.present? ? "#{value}#{unit}" : value
  end

  def value
  end
  
  def get_value_from_arduino
  end
  
  def set_value_to_arduino
  end

  def value_attribute
    nil
  end

  def get_current_chart_data
    if value_boolean != nil
      value_boolean? ? 1 : 0
    elsif value_integer != nil
      unit.present? ? "#{value_integer}#{unit}" : value_integer
    elsif value_decimal != nil
      unit.present? ? "#{value_decimal}#{unit}" : value_decimal
    else
      1
    end
  end

  def clear_logs
    logs_to_clear = device_logs.where("created_at < ?", Time.current - days_to_preserve_logs.days)
    logs_to_clear.delete_all
  end

  protected

  def detect_hw_change
    if board_id_previously_changed?
      board_id_previous_change.compact.each { |b_id| Board.find(b_id).set_pins }
    elsif pin_previously_changed? || device_type_previously_changed? || poll_previously_changed? || inverted_previously_changed?
      reset_pins
    end
  end

  def detect_log_enabled_change
    if log_enabled_previously_changed? && !log_enabled
      device_logs.delete_all
    end
  end


  def send_to_arduino(data)
    board.send_to_arduino(data)
  end

  def trigger_programs
    Program.joins(:programs_devices).where(programs_devices: { device_id: self.id, trigger: true }, program_type: Program::ProgramType::DEFAULT, enabled: true).each(&:run)
  end

  def log_device_log
  end

  def reset_pins
    board.set_pins
  end

  private

  def self.ransackable_attributes(auth_object = nil)
    authorizable_ransackable_attributes
  end

  def self.ransackable_associations(auth_object = nil)
    authorizable_ransackable_associations
  end
end