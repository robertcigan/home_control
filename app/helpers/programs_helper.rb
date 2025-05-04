module ProgramsHelper
  def time_between(start_time, end_time) # "4:00 format"
    (Time.zone.parse(start_time) <= Time.current) && (Time.zone.parse(end_time) >= Time.current)
  end

  def program_log(level, message)
    timestamp = Time.current.strftime("%Y-%m-%d %H:%M:%S")
    self.output += "[#{timestamp}] #{level.upcase}: #{message}\n"
  end

  def log_debug(message)
    program_log(:debug, message)
  end

  def log_info(message)
    program_log(:info, message)
  end

  def log_warn(message)
    program_log(:warn, message)
  end

  def log_error(message)
    program_log(:error, message)
  end
end