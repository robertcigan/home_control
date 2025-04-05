class Device::Switch < Device
  after_commit :detect_change

  validates :board, presence: true

  def set(new_value)
    update(value: new_value)
  end

  def status
    value
  end

  def indication
    value ? "on" : "off"
  end

  def value
    value_boolean
  end

  def value=(input)
    self.value_boolean = input
  end

  def setup_pin
    send_to_board(add: { id: id, type: "switch", pin: pin, poll: poll || 250, inverted: inverted } )
  end

  def readable?
    true
  end

  def poll?
    true
  end

  def get_value_from_board
    send_to_board(read: { id: id })
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

  def log_device_log
    if value_boolean_changed?
      self.last_change = Time.current
      device_logs.build(value_boolean: value_boolean)
    end
  end
end