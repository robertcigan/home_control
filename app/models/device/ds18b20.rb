class Device::Ds18b20 < Device
  after_commit :detect_change

  validates :board, presence: true

  def set(new_value)
    update(value: new_value)
  end
  
  def status
    value
  end
  
  def indication
    unit.present? ? "#{value}#{unit}" : "#{value}°C"
  end
  
  def value
    value_decimal
  end
  
  def value=(input)
    self.value_decimal = input
  end

  def get_value_from_arduino
    send_to_arduino(read: { id: id })
  end

  def setup_pin
    send_to_arduino(add: { id: id, type: "ds18b20", pin: pin, poll: poll || 30000 } )
  end

  def readable_value?
    true
  end

  def poll?
    true
  end

  def value_attribute
    :value_decimal
  end

  protected
  
  def detect_change
    if previous_changes.key?(:value_decimal)
      trigger_programs
    end
  end
  
  def log_device_log
    device_logs.build(value_decimal: value_decimal) if value_decimal_changed?
  end
end