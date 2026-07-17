require "rails_helper"

RSpec.describe WebsocketPushChange, type: :model do
  describe "Device" do
    let!(:relay) { create(:relay, value_boolean: false) }

    it "broadcasts on update with devices channel and json_data payload" do
      expect do
        relay.update!(value_boolean: true)
      end.to have_broadcasted_to("devices").with(hash_including("id" => relay.id))
    end

    it "does not broadcast on create" do
      expect do
        create(:relay)
      end.not_to have_broadcasted_to("devices")
    end

    it "does not broadcast on destroy" do
      expect do
        relay.destroy
      end.not_to have_broadcasted_to("devices")
    end
  end

  describe "Board" do
    let!(:board) { create(:board) }

    it "broadcasts to boards channel" do
      expect do
        board.update!(name: "Updated Board")
      end.to have_broadcasted_to("boards").with(hash_including("id" => board.id))
    end
  end

  describe "Program" do
    let!(:program) { create(:program) }

    it "broadcasts to programs channel" do
      expect do
        program.update!(name: "Updated Program")
      end.to have_broadcasted_to("programs").with(hash_including("id" => program.id))
    end
  end

  describe "Panel" do
    let!(:panel) { create(:panel) }

    it "broadcasts to panels channel" do
      expect do
        panel.update!(name: "Updated Panel")
      end.to have_broadcasted_to("panels").with(hash_including("id" => panel.id))
    end
  end

  describe "#websocket_channel_name" do
    it "derives channel name from base class" do
      relay = build(:relay)
      expect(relay.websocket_channel_name).to eq("devices")
    end
  end
end
