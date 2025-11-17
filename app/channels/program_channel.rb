# app/channels/chat_channel.rb
class ProgramChannel < ApplicationCable::Channel
  def subscribed
    puts "programs subscribed" unless Rails.env.test?
    stream_from "programs"
  end
end