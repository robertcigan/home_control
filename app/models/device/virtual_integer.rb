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

  def writable?
    virtual_writable? && board.board_type_modbus_tcp?
  end

  def set_value_to_board
    send_to_board({ device_id: id })
  end

  protected

  def detect_change
    if previous_changes.key?(:value_integer)
      set_value_to_board if writable?
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