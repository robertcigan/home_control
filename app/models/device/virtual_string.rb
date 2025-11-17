class Device::VirtualString < Device
  after_commit :detect_change

  def set(new_value)
    update(value: new_value)
  end

  def status
    value
  end

  def value
    value_string
  end

  def value=(input)
    self.value_string = input
  end

  def value_attribute
    :value_string
  end

  protected

  def detect_change
    if previous_changes.key?(:value_string)
      trigger_programs
    end
  end

  def reset_pins
  end

  def log_device_log
    if value_string_changed?
      self.last_change = Time.current
      device_logs.build(value_string: value_string)
    end
  end
end