module LogCompression
  extend ActiveSupport::Concern

  def compressable?
    value_attribute == :value_decimal || value_attribute == :value_integer
  end

  def round_to_min10(time = Time.current)
    time.change(min: (time.min / 10) * 10, sec: 0)
  end

  def run_compression(replace_lpgs = false)
    compression_time_calculated = if compression_last_run_at.nil?
      if device_logs.count > 0
        if compression_timespan_min10?
          round_to_min10(device_logs.order(:created_at).first.created_at)
        elsif compression_timespan_hour?
          device_logs.order(:created_at).first.created_at.beginning_of_hour
        elsif compression_timespan_day?
          device_logs.order(:created_at).first.created_at.beginning_of_day
        end
      else
        nil
      end
    else
      if compression_timespan_min10?
        round_to_min10(compression_last_run_at + 10.minutes)
      elsif compression_timespan_hour?
        (compression_last_run_at + 1.hour).beginning_of_hour
      elsif compression_timespan_day?
        (compression_last_run_at + 1.day).beginning_of_day
      end
    end
    backlog_calculated = if compression_timespan_min10?
      compression_backlog * 600
    elsif compression_timespan_hour?
      compression_backlog * 3600
    elsif compression_timespan_day?
      compression_backlog * 86400
    end
    if compression_time_calculated && (Time.current - compression_time_calculated) > backlog_calculated
      compress_logs(compression_time_calculated, replace_lpgs)
    else
      nil
    end
  end

  # calculation - :w_average, :average, :end_value
  # timespan - :hour
  def compress_logs(time, replace_logs = false) 
    self.class.transaction do
      if compression_timespan_min10?
        starts_at = round_to_min10(time)
        ends_at = (time + 9.minutes).end_of_minute
      elsif compression_timespan_hour?
        starts_at = time.beginning_of_hour
        ends_at = time.end_of_hour
      elsif compression_timespan_day?
        starts_at = time.beginning_of_day
        ends_at = time.end_of_day
      end
      device_logs_timespan = device_logs.where("created_at >= ? AND created_at < ?", starts_at, ends_at)
      device_log_count = device_logs_timespan.count
      if device_log_count > 1
        Rails.logger.debug "Device #{id} compressing logs #{starts_at} - #{ends_at}"
        new_device_log = case compression_type
          when Device::CompressionType::AVERAGE
            new_device_log = device_logs.build(
              created_at: starts_at,
              value_attribute => device_logs_timespan.average(value_attribute)
            )
          when Device::CompressionType::W_AVERAGE
            device_logs_objects = [device_logs.where("created_at < ?", starts_at).order(:created_at).last] + device_logs_timespan.order(:created_at).load.to_a
            total_weight_value = 0
            device_logs_objects.each_with_index do |device_log, i|
              unless device_log.nil? || device_log.send(value_attribute).nil?                    
                total_weight_value += if i == 0 #first when value is in the previous timespan
                  device_log.send(value_attribute) * (device_logs_objects[1].created_at - starts_at)
                elsif i == device_log_count #last
                  device_log.send(value_attribute) * (ends_at - device_log.created_at)
                else
                  device_log.send(value_attribute) * (device_logs_objects[i + 1].created_at - device_log.created_at)
                end
              end
            end
            new_device_log = device_logs.build(
              created_at: starts_at,
              value_attribute => total_weight_value / (ends_at - starts_at)
            )
          when Device::CompressionType::END_VALUE
            device_logs.build(
              created_at: starts_at,
              value_attribute => device_logs_timespan.order(:created_at).last.send(value_attribute)
            )
          else
          end
        if replace_logs
          device_logs_timespan.delete_all

          new_device_log.save!
          update!(compression_last_run_at: time)
          new_device_log
        else
          new_device_log
        end
      else
        if replace_logs
          update!(compression_last_run_at: time)
        end
        nil
      end
    end
  end
end
