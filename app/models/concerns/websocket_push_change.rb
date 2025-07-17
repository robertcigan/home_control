module WebsocketPushChange
  extend ActiveSupport::Concern

  included do
    after_commit :push_value_change, on: [:update]
  end

  def websocket_channel_name
    self.class.name.split("::").first.downcase.pluralize
  end

  def push_value_change
    ActionCable.server.broadcast(websocket_channel_name, json_data)
  end

  def json_data
    { id: id }
  end
end