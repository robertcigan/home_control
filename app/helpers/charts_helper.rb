module ChartsHelper
  def chart_options(min, max, options = {})
    options[:stepped] = false if options[:stepped].nil?
    options[:points] = true if options[:points].nil?
    options[:curved] = false if options[:curved].nil?
    options[:refresh] = 0 if options[:refresh].nil?
    options[:title_y] = "Value" if options[:title_y].nil?
    options[:lines] = true if options[:lines].nil?
    options[:type] = "line" if options[:type].nil?

    timespan = max - min
    unit = if timespan >= 10.months.to_i
      "month"
    elsif timespan >= 5.days.to_i
      "day"
    elsif timespan >= 12.hours.to_i
      "hour"
    elsif timespan > 30.minutes.to_i 
      "minute"
    else
      "second"
    end

    chart_options = {
      type: options[:type],
      curve: options[:curved],
      points: options[:points],
      refresh: options[:refresh],
      dataset: { stepped: options[:stepped], showLine: options[:lines] },
      library: {
        scales: {
          x: {
            type: 'time',
            max: max,
            min: min,
            time: {
              tooltipFormat: Rails.configuration.home_control.luxon_formats[:time],
              isoWeekday: true,
              unit: unit,
              displayFormats: {
                month: Rails.configuration.home_control.luxon_formats[:month], 
                day: Rails.configuration.home_control.luxon_formats[:day],
                hour: Rails.configuration.home_control.luxon_formats[:hour],
                minute: Rails.configuration.home_control.luxon_formats[:minute],
                second: Rails.configuration.home_control.luxon_formats[:second]
              }
            },
            title: {
              display: true,
              text: 'Date/Time'
            }
          },
          y: {
            title: {
              display: true,
              text: options[:title_y]
            }
          }
        }
      }
    }    
  end
end