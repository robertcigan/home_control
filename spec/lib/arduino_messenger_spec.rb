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

    it "keeps the following partial line after an invalid line" do
      messenger = build_messenger
      messenger.instance_variable_set(:@received_data_buffer, "not-json\n{\"partial\":")
      messenger.process_buffer
      expect(messenger.instance_variable_get(:@received_data_buffer)).to eq("{\"partial\":")
    end

    it "continues with the next line after an invalid one" do
      messenger = build_messenger
      expect(board).to receive(:parse).with(hash_including("pong" => true)).once
      messenger.instance_variable_set(:@received_data_buffer, "not-json\n{\"pong\":true}\n")
      messenger.process_buffer
    end

    it "ignores valid JSON that is not an object" do
      messenger = build_messenger
      expect(board).not_to receive(:parse)
      messenger.instance_variable_set(:@received_data_buffer, "5\n[1]\nnull\n")
      expect { messenger.process_buffer }.not_to raise_error
      expect(messenger.instance_variable_get(:@received_data_buffer)).to eq("")
    end

    it "does not raise when the board fails to process a message" do
      messenger = build_messenger
      allow(board).to receive(:parse).and_raise(ActiveRecord::ConnectionNotEstablished)
      messenger.instance_variable_set(:@received_data_buffer, "{\"pong\":true}\n")
      expect { messenger.process_buffer }.not_to raise_error
    end

    it "accumulates data split across packets" do
      messenger = build_messenger
      expect(board).to receive(:parse).with(hash_including("pong" => true))
      messenger.receive_data("{\"po")
      messenger.receive_data("ng\":true}\r\n")
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

    it "closes the connection instead of raising when the database fails" do
      messenger = build_messenger
      allow(Board).to receive(:where).and_raise(ActiveRecord::ConnectionNotEstablished)
      expect(messenger).to receive(:close_connection)
      expect { messenger.post_init }.not_to raise_error
      expect(described_class.connected_clients).to be_empty
    end
  end

  describe "over a real TCP connection" do
    module FakeArduinoBoard
      def initialize(lines)
        @lines = lines
      end

      def connection_completed
        @lines.each { |line| send_data(line) }
        EM.add_timer(0.3) { close_connection }
      end
    end

    it "survives malformed messages, applies valid ones and marks the board disconnected on close" do
      local_board = create(:board, ip: "127.0.0.1")
      port = nil
      EM.run do
        server = EM.start_server("127.0.0.1", 0, described_class)
        port = Socket.unpack_sockaddr_in(EM.get_sockname(server)).first
        allow(EventMachine::Timer).to receive(:new) # skip the initial device read/write
        EM.connect("127.0.0.1", port, FakeArduinoBoard, [
          "5\nnot-json\n",
          "{\"pong\":true,\"version\":\"1.2\",\"ssid\":\"ho",
          "me\",\"rssi\":-60}\r\n"
        ])
        EM.add_timer(0.15) do
          expect(described_class.connected_clients.map(&:ip)).to eq(["127.0.0.1"])
          expect(local_board.reload.ssid).to eq("home")
        end
        EM.add_timer(0.6) { EM.stop }
      end
      expect(described_class.connected_clients).to be_empty
      expect(local_board.reload.connected_at).to be_nil
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

    it "does not disconnect the board when a rejected duplicate connection closes" do
      active = build_messenger
      described_class.class_variable_set(:@@connected_clients, [active])
      duplicate = build_messenger
      expect(board).not_to receive(:disconnected!)
      duplicate.unbind
      expect(described_class.connected_clients).to eq([active])
    end

    it "removes the client even when the database fails" do
      messenger = build_messenger
      described_class.class_variable_set(:@@connected_clients, [messenger])
      allow(board).to receive(:reload).and_raise(ActiveRecord::ConnectionNotEstablished)
      expect { messenger.unbind }.not_to raise_error
      expect(described_class.connected_clients).to be_empty
    end
  end
end
