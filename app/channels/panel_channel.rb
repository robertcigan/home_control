class PanelChannel < ApplicationCable::Channel
  def subscribed
    puts "panels subscribed" unless Rails.env.test?
    stream_from "panels"
  end
end