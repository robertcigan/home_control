class Device::Button < Device
  after_commit :detect_change

  validates :board, presence: true

  def set(value = nil)
    update(last_change: Time.current)
  end

  def status
    I18n.l(last_change) if last_change
  end
  
  def indication
    last_change_text
  end
  
  def value
    last_change
  end
  
  def value=(input)
    self.last_change = input
  end
  
  def setup_pin
    send_to_arduino(add: { id: id, type: "button", pin: pin, poll: poll || 50, inverted: inverted } )
  end

  def poll?
    true
  end

  # def value_attribute
  #   :last_change
  # end

  protected
  
  def detect_change
    if previous_changes.key?(:last_change)
      trigger_programs
    end
  end
  
  def log_device_log
    device_logs.build if last_change_changed?
  end
end