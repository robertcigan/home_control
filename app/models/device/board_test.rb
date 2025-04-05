class Device::BoardTest < Device
  validates :board, presence: true

  def activate
    board_test
    update(last_change: Time.current)
  end

  def status
    I18n.l(last_change) if last_change
  end

  def indication
    last_change_text
  end

  private

  def board_test
    send_to_board("t")
  end

  def log_device_log
    device_logs.build if last_change_changed?
  end
end