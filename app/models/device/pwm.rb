class Device::Pwm < Device
  after_commit :detect_change

  validates :value_integer, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100, allow_nil: true }
  validates :board, presence: true

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

  def setup_pin
    send_to_board(add: { id: id, type: "pwm", pin: pin, default_value: value } )
    set_value_to_board
  end

  def writable?
    true
  end

  def set_value_to_board
    send_to_board(write: { id: id, type: "pwm", value: value})
  end

  def toggle?
    false
  end

  def value_attribute
    :value_integer
  end

  protected

  def detect_change
    if previous_changes.key?(:value_integer)
      set_value_to_board
      trigger_programs
    end
  end

  def log_device_log
    if value_integer_changed?
      self.last_change = Time.current
      device_logs.build(value_integer: value_integer)
    end
  end
end