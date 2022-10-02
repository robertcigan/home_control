class Device::VirtualBoolean < Device
  after_commit :detect_change
  
  def set(new_value)
    update(value: new_value)
  end
  
  def status
    value_boolean
  end
  
  def indication
    value_boolean ? "true" : "false"
  end
  
  def value
    value_boolean
  end
  
  def value=(input)
    self.value_boolean = input
  end
  
  def toggle?
    true
  end

  def value_attribute
    :value_boolean
  end
  
  protected
  
  def detect_change
    if previous_changes.key?(:value_boolean)
      trigger_programs
    end
  end
  
  def reset_pins
  end
  
  def log_device_log
    if value_boolean_changed?
      self.last_change = Time.current
      device_logs.build(value_boolean: value_boolean) 
    end
  end
end