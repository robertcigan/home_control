class ArduinoChannel < ApplicationCable::Channel
  def subscribed
    puts "arduino subscribed" unless Rails.env.test?
    stream_from "arduino"
  end
end