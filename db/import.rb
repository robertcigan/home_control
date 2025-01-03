require 'csv'
require 'pry'
boards_conversion = {}
devices_conversion = {}
panels_conversion = {}
programs_conversion = {}

Board.transaction do 
  CSV.foreach("tmp/board.csv") do |row|
    board = Board.new(
      ip: row[1],
      name: row[2],
      created_at: row[3],
      updated_at: row[4],
      connected_at: row[5],
      board_type: row[6],
      ssid: row[7],
      signal_strength: row[8],
      version: row[9],
      slave_address: row[10],
      data_read_interval: row[11],
      days_to_preserve_logs: row[12]
    )
    board.save!
    boards_conversion[row[0]] = board.id
    puts board.attributes
  end

  CSV.foreach("tmp/device.csv") do |row|
    device = Device.new(
      name: row[1],
      device_type: row[2],
      pin: row[3],
      created_at: row[4],
      updated_at: row[5],
      board_id: boards_conversion[row[6]],
      last_change: row[7],
      type: row[8],
      value_integer: row[9],
      value_boolean: row[10],
      value_string: row[11],
      value_decimal: row[12],
      inverted: row[13],
      poll: row[14],
      holding_register_address: row[15],
      scale: row[16],
      unit: row[17],
      modbus_data_type: row[18],
      compression_type: row[19],
      compression_timespan: row[20],
      compression_backlog: row[21],
      compression_last_run_at: row[22],
      days_to_preserve_logs: row[23],
      log_enabled: row[24]
    )
    device.save!
    devices_conversion[row[0]] = device.id
    puts device.attributes
  end

  CSV.foreach("tmp/panel.csv") do |row|
    panel = Panel.new(
      name: row[1],
      created_at: row[2],
      updated_at: row[3],
      row: row[4],
      column: row[5],
      public_access: row[6]
    )
    panel.save!
    panels_conversion[row[0]] = panel.id
    puts panel.attributes
  end

  CSV.foreach("tmp/program.csv") do |row|
    program = Program.new(
      name: row[1],
      program_type: row[2],
      code: row[3],
      created_at: row[4],
      updated_at: row[5],
      repeat_every: row[6],
      last_error_message: row[7],
      last_run: row[8],
      storage: row[9],
      enabled: row[10],
      runtime: row[11],
      last_error_at: row[12]
    )
    program.save!
    programs_conversion[row[0]] = program.id
    puts program.attributes
  end

  CSV.foreach("tmp/widget.csv") do |row|
    widget = Widget.new(
      panel_id: panels_conversion[row[1]],
      widget_type: row[2],
      device_id: devices_conversion[row[3]],
      program_id: programs_conversion[row[4]],
      x: row[5],
      y: row[6],
      w: row[7],
      h: row[8],
      created_at: row[9],
      updated_at: row[10],
      color_1: row[11],
      color_2: row[12],
      icon: row[13],
      name: row[14],
      show_updated: row[15],
      show_label: row[16]
    )
    widget.save!
    puts widget.attributes
  end

  CSV.foreach("tmp/programsdevice.csv") do |row|
    programs_device = ProgramsDevice.new(
      program_id: programs_conversion[row[1]],
      device_id: devices_conversion[row[2]],
      created_at: row[3],
      updated_at: row[4],
      variable_name: row[5],      
      trigger: row[6]
    )
    programs_device.save!
    puts programs_device.attributes
  end

  CSV.foreach("tmp/boardlog.csv") do |row|
    board_log = BoardLog.new(
      board_id: boards_conversion[row[1]],
      created_at: row[2],
      updated_at: row[3],
      connected: row[4],
      signal_strength: row[5],
      ssid: row[6]
    )
    board_log.save!
    putc '.'
    puts board_log.id if board_log.id % 1000 == 0
  end

  CSV.foreach("tmp/devicelog.csv") do |row|
    device_log = DeviceLog.new(
      device_id: devices_conversion[row[1]],
      created_at: row[2],
      updated_at: row[3],
      value_integer: row[4],
      value_boolean: row[5],
      value_string: row[6],
      value_decimal: row[7]
    )
    device_log.save!
    putc '.'
    puts device_log.id if device_log.id % 1000 == 0
  end
  

  # raise ActiveRecord::Rollback
  puts "FINISHED"
end