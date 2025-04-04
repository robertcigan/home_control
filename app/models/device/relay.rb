class Device::Relay < Device
  after_commit :detect_change

  validates :board, presence: true

  def set(new_value)
    update(value: new_value)
  end

  def status
    value
  end

  def indication
    value_boolean ? "on" : "off"
  end

  def value
    value_boolean
  end

  def value=(input)
    self.value_boolean = input
  end

  def setup_pin
    send_to_board(add: { id: id, type: "relay", pin: pin, default_value: value, inverted: inverted } )
    set_value_to_board
  end

  def writable?
    true
  end

  def set_value_to_board
    send_to_board(write: { id: id, type: "relay", value: value})
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
      set_value_to_board
      trigger_programs
    end
  end

  def log_device_log
    if value_boolean_changed?
      self.last_change = Time.current
      device_logs.build(value_boolean: value_boolean)
    end
  end
end