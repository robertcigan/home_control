require "rails_helper"
require "arduino_messenger"

RSpec.describe ArduinoMessenger do
  let(:board) { create(:board, ip: "192.168.1.77") }

  def build_messenger(ip: board.ip, connected_board: board)
    messenger = described_class.allocate
    messenger.instance_variable_set(:@received_data_buffer, "")
    messenger.instance_variable_set(:@board, connected_board)
    messenger.instance_variable_set(:@ip, ip)
    messenger.instance_variable_set(:@largest_data, 0)
    allow(messenger).to receive(:get_peername).and_return(Socket.pack_sockaddr_in(80, ip))
    messenger
  end

  before do
    described_class.class_variable_set(:@@connected_clients, [])
  end

  describe "#process_buffer" do
    it "parses a complete JSON line and routes it to the board" do
      messenger = build_messenger
      expect(board).to receive(:parse).with(hash_including("type" => "pong"))
      messenger.instance_variable_set(:@received_data_buffer, "{\"type\":\"pong\"}\n")
      messenger.process_buffer
      expect(messenger.instance_variable_get(:@received_data_buffer)).to eq("")
    end

    it "parses multiple JSON lines in one packet" do
      messenger = build_messenger
      expect(board).to receive(:parse).twice
      messenger.instance_variable_set(:@received_data_buffer, "{\"a\":1}\n{\"b\":2}\n")
      messenger.process_buffer
      expect(messenger.instance_variable_get(:@received_data_buffer)).to eq("")
    end

    it "keeps trailing partial JSON in the buffer" do
      messenger = build_messenger
      expect(board).to receive(:parse).once
      messenger.instance_variable_set(:@received_data_buffer, "{\"a\":1}\n{\"partial\":")
      messenger.process_buffer
      expect(messenger.instance_variable_get(:@received_data_buffer)).to eq("{\"partial\":")
    end

    it "resets buffer on invalid JSON" do
      messenger = build_messenger
      messenger.instance_variable_set(:@received_data_buffer, "not-json\n")
      messenger.process_buffer
      expect(messenger.instance_variable_get(:@received_data_buffer)).to eq("")
    end

    it "resets buffer on overflow" do
      messenger = build_messenger
      messenger.instance_variable_set(:@received_data_buffer, "x" * (10_000_001))
      messenger.process_buffer
      expect(messenger.instance_variable_get(:@received_data_buffer)).to eq("")
    end
  end

  describe "#post_init" do
    it "connects a known board IP" do
      messenger = build_messenger
      allow(messenger).to receive(:close_connection)
      allow(messenger).to receive(:comm_inactivity_timeout=)
      allow(EventMachine::Timer).to receive(:new)
      expect_any_instance_of(Board).to receive(:connected!)
      messenger.post_init
      expect(described_class.connected_clients).to include(messenger)
    end

    it "rejects unknown board IP" do
      messenger = build_messenger(ip: "10.0.0.9", connected_board: nil)
      allow(messenger).to receive(:close_connection) do
        messenger.instance_variable_set(:@board, nil)
      end
      messenger.post_init
      expect(described_class.connected_clients).to be_empty
    end

    it "rejects duplicate IP connections" do
      existing = build_messenger
      described_class.class_variable_set(:@@connected_clients, [existing])
      messenger = build_messenger
      expect(messenger).to receive(:close_connection)
      messenger.post_init
      expect(described_class.connected_clients.size).to eq(1)
    end
  end

  describe "#unbind" do
    it "disconnects board and removes client" do
      messenger = build_messenger
      described_class.class_variable_set(:@@connected_clients, [messenger])
      expect(board).to receive(:reload).and_return(board)
      expect(board).to receive(:disconnected!)
      messenger.unbind
      expect(described_class.connected_clients).to be_empty
    end
  end
end
