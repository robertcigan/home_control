# app/channels/chat_channel.rb
class BoardChannel < ApplicationCable::Channel
  def subscribed
    puts "boards subscribed"
    stream_from "boards"
  end
end