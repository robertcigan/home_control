class ModbusChannel < ApplicationCable::Channel
  def subscribed
    puts "modbus subscribed" unless Rails.env.test?
    stream_from "modbus"
  end
end