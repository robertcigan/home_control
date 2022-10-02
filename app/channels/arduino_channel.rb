class ArduinoChannel < ApplicationCable::Channel
  def subscribed
    puts "arduino subscribed"
    stream_from "arduino"
  end
end