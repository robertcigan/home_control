module ProgramsHelper
  def time_between(start_time, end_time) # "4:00 format"
    (Time.zone.parse(start_time) <= Time.current) && (Time.zone.parse(end_time) >= Time.current)
  end
end