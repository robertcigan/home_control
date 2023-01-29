class Device::AnalogInput < Device
  after_commit :detect_change

  validates :board, presence: true

  def set(new_value)
    update(value: new_value)
  end
  
  def status
    value
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
    send_to_arduino(add: { id: id, type: "analog_input", pin: pin, poll: poll || 5000 } )
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
    if value_decimal_changed?
      self.last_change = Time.current
      device_logs.build(value_decimal: value_decimal)
    end 
  end
end