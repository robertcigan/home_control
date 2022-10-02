class PanelChannel < ApplicationCable::Channel
  def subscribed
    puts "panels subscribed"
    stream_from "panels"
  end
end