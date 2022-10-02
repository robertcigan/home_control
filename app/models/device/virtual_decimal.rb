class Device::VirtualDecimal < Device
  after_commit :detect_change
  
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

  def value_attribute
    :value_decimal
  end
  
  protected
  
  def detect_change
    if previous_changes.key?(:value_decimal)
      trigger_programs
    end
  end
  
  def reset_pins
  end
  
  def log_device_log
    if value_decimal_changed?
      self.last_change = Time.current
      device_logs.build(value_decimal: value_decimal) 
    end
  end
end