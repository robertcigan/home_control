# app/channels/chat_channel.rb
class DeviceChannel < ApplicationCable::Channel
  def subscribed
    puts "devices subscribed" unless Rails.env.test?
    stream_from "devices"
  end
end