class ModbusChannel < ApplicationCable::Channel
  def subscribed
    puts "modbus subscribed"
    stream_from "modbus"
  end
end