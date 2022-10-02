class Device::VirtualInteger < Device
  after_commit :detect_change
  
  def set(new_value)
    update(value: new_value)
  end
  
  def status
    value
  end
  
  def value
    value_integer
  end
  
  def value=(input)
    self.value_integer = input
  end

  def value_attribute
    :value_integer
  end
  
  protected
  
  def detect_change
    if previous_changes.key?(:value_integer)
      trigger_programs
    end
  end
  
  def reset_pins
  end
  
  def log_device_log
    if value_integer_changed?
      self.last_change = Time.current
      device_logs.build(value_integer: value_integer)
    end
  end
end