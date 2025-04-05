class Device::Sound < Device

  validates :board, presence: true

  def activate(*args)
    play_sound(*args)
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
    send_to_board(add: { id: id, type: "player" } )
  end

  protected

  def volume(vol)
    send_to_board(write: { id: id, volume: vol})
  end

  def play_sound(vol, dir, file)
    send_to_board(write: { id: id, volume: vol})
    send_to_board(write: { id: id, directory: dir, file: file })
  end

  def log_device_log
    device_logs.build if last_change_changed?
  end
end