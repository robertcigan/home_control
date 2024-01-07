class Device::Curtain < Device
  validates :board, presence: true
  
  def activate(*args)
    activate_curtain(*args)
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
    send_to_arduino(add: { id: id, type: "curtain", open_pin: pin, close_pin: pin + 1, inverted: inverted } )
    set_value_to_arduino
  end
   
  protected

  def activate_curtain(direction, time) #time in ms
    if direction == "open"
      send_to_arduino(write: { id: id, action: "open", value: time})
    elsif direction == "close"
      send_to_arduino(write: { id: id, action: "close", value: time })
    end
  end
 
  def log_device_log
    device_logs.build if last_change_changed?
  end
end