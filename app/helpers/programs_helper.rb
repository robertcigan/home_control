module ProgramsHelper
  def time_between(start_time, end_time) # "4:00 format"
    (Time.zone.parse(start_time)..Time.zone.parse(end_time)).include?(Time.current)
  end
end