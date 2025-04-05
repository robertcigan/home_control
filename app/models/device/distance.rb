class Device::Distance < Device
  after_commit :detect_change

  validates :board, presence: true

  def set(new_value)
    update(value: new_value)
  end

  def status
    value
  end

  def indication
    unit.present? ? "#{value}#{unit}" : "#{value}cm"
  end

  def value
    value_integer
  end

  def value=(input)
    self.value_integer = input
  end

  def setup_pin
    send_to_board(add: { id: id, type: "distance", write_pin: pin, read_pin: pin + 1, poll: poll || 30000 } )
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
    :value_integer
  end

  protected

  def detect_change
    if previous_changes.key?(:value_integer)
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