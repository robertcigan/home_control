require "rails_helper"

RSpec.describe Board, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:ip) }
  end

  describe "associations" do
    it { should have_many(:devices).dependent(:restrict_with_error) }
    it { should have_many(:board_logs).dependent(:delete_all) }
  end

  describe "scopes" do
    let!(:modbus_board) { create(:board, :modbus_tcp) }
    let!(:arduino_board) { create(:board) }

    describe ".ip" do
      it "filters boards by IP address" do
        expect(Board.ip(arduino_board.ip)).to include(arduino_board)
        expect(Board.ip("192.168.1.100")).not_to include(arduino_board)
      end
    end

    describe ".modbus_tcp" do
      it "returns only modbus TCP boards" do
        expect(Board.modbus_tcp).to include(modbus_board)
        expect(Board.modbus_tcp).not_to include(arduino_board)
      end
    end

    describe ".for_log_clear" do
      let!(:board_with_logs) { create(:board, days_to_preserve_logs: 7) }
      let!(:board_without_logs) { create(:board, days_to_preserve_logs: nil) }

      it "returns boards with days_to_preserve_logs set" do
        expect(Board.for_log_clear).to include(board_with_logs)
        expect(Board.for_log_clear).not_to include(board_without_logs)
      end
    end
  end

  describe "#to_s" do
    let(:board) { create(:board) }

    it "returns the board name" do
      expect(board.to_s).to eq(board.name)
    end
  end

  describe "#connected?" do
    let(:board) { create(:board) }

    it "returns true when connected_at is present" do
      board.connected_at = Time.current
      expect(board.connected?).to be true
    end

    it "returns false when connected_at is older than 25 seconds" do
      board.connected_at = 30.seconds.ago
      expect(board.connected?).to be false
    end

    it "returns false when connected_at is nil" do
      board.connected_at = nil
      expect(board.connected?).to be false
    end
  end

  describe "#send_to_board" do
    let(:board) { create(:board) }

    it "sends data to the board" do
      # This would typically involve mocking the actual board communication
      expect { board.send_to_board("test_data") }.not_to raise_error
    end
  end

  describe "#reset_devices" do
    let!(:board) { create(:board) }

    it "resets all devices on the arduino board" do
      expect(board).to receive(:send_to_arduino).with({ reset_devices: true })
      board.reset_devices
    end

    it "resets devices on the esp board" do
      board.board_type = Board::BoardType::ESP
      expect(board).to receive(:send_to_arduino).with({ reset_devices: true })
      board.reset_devices
    end

    it "does not reset devices on the modbus board" do
      board.board_type = Board::BoardType::MODBUS_TCP
      expect(board).not_to receive(:send_to_modbus)
      board.reset_devices
    end
  end

  describe "#set_pins" do
    let!(:board) { create(:board) }

    it "sets pins for all devices on the board" do
      create(:switch, board: board, pin: 1)
      create(:relay, board: board, pin: 2)
      board.reload
      expect_any_instance_of(Device::Switch).to receive(:setup_pin)
      expect_any_instance_of(Device::Relay).to receive(:setup_pin)
      board.set_pins
    end
  end

  describe "#parse" do
    let(:board) { create(:board) }

    it "calls connected! with version, ssid, and signal_strength when parsing \"pong\" data" do
      pong_data = {
        "pong" => true,
        "version" => "1.0.0",
        "ssid" => "TestWiFi",
        "rssi" => -50
      }
      expect(board).to receive(:connected!).with(
        version: "1.0.0",
        ssid: "TestWiFi",
        signal_strength: -50
      )
      board.parse(pong_data)
    end

    it "calls set_pins when parsing \"send_devices\" data" do
      send_devices_data = { "send_devices" => true }
      expect(board).to receive(:set_pins)
      board.parse(send_devices_data)
    end

    it "sets the device value when parsing device data with value" do
      device = create(:switch, board: board)
      device_data = {
        "device" => {
          "id" => device.id,
          "value" => true
        }
      }
      expect_any_instance_of(Device::Switch).to receive(:set).with(true)
      board.parse(device_data)
    end

    it "calls set without value for button devices when parsing device data" do
      button_device = create(:button, board: board)
      button_data = {
        "device" => {
          "id" => button_device.id
        }
      }
      expect_any_instance_of(Device::Button).to receive(:set)
      board.parse(button_data)
    end

    it "does not raise an error when parsing device data with non-existent device" do
      invalid_device_data = {
        "device" => {
          "id" => 99999,
          "value" => 100
        }
      }
      expect { board.parse(invalid_device_data) }.not_to raise_error
    end

    it "does not raise an error when parsing device data with missing device id" do
      invalid_data = {
        "device" => {
          "value" => 100
        }
      }
      expect { board.parse(invalid_data) }.not_to raise_error
    end

    it "does not raise an error when parsing device data with missing device data" do
      invalid_data = { "device" => nil }
      expect { board.parse(invalid_data) }.not_to raise_error
    end

    it "does not raise an error when parsing unknown data" do
      unknown_data = { "unknown_key" => "value" }
      expect { board.parse(unknown_data) }.not_to raise_error
    end

    it "does not raise an error when parsing empty data" do
      empty_data = {}
      expect { board.parse(empty_data) }.not_to raise_error
    end
  end

  describe "#json_data" do
    let(:board) { create(:board, ssid: "TestWiFi", signal_strength: 75) }

    it "includes board status, ssid, and signal strength" do
      json_data = board.json_data
      expect(json_data).to include(:status, :ssid, :"signal-strength")
      expect(json_data[:ssid]).to eq("TestWiFi")
      expect(json_data[:"signal-strength"]).to eq(75)
    end
  end

  describe "#ping" do
    let(:board) { create(:board) }

    it "sends ping data to arduino for arduino_mega_8b board" do
      expect(board).to receive(:send_to_arduino).with({ ping: true })
      board.ping
    end

    it "sends ping data to arduino for esp board" do
      board.board_type = Board::BoardType::ESP
      expect(board).to receive(:send_to_arduino).with({ ping: true })
      board.ping
    end

    it "does not send ping data for modbus_tcp board" do
      board.board_type = Board::BoardType::MODBUS_TCP
      expect(board).not_to receive(:send_to_arduino)
      board.ping
    end
  end

  describe "#reset_devices" do
    let(:board) { create(:board) }

    it "sends reset_devices data to arduino for arduino_mega_8b board" do
      expect(board).to receive(:send_to_arduino).with({ reset_devices: true })
      board.reset_devices
    end

    it "sends reset_devices data to arduino for esp board" do
      board.board_type = Board::BoardType::ESP
      expect(board).to receive(:send_to_arduino).with({ reset_devices: true })
      board.reset_devices
    end

    it "does not send reset_devices data for modbus_tcp board" do
      board.board_type = Board::BoardType::MODBUS_TCP
      expect(board).not_to receive(:send_to_arduino)
      board.reset_devices
    end
  end

  describe "#send_to_board" do
    let(:board) { create(:board) }
    let(:data) { { test: "data" } }

    it "sends data to arduino for arduino_mega_8b board" do
      expect(board).to receive(:send_to_arduino).with(data)
      board.send_to_board(data)
    end

    it "sends data to arduino for esp board" do
      board.board_type = Board::BoardType::ESP
      expect(board).to receive(:send_to_arduino).with(data)
      board.send_to_board(data)
    end

    it "sends data to modbus for modbus_tcp board" do
      board.board_type = Board::BoardType::MODBUS_TCP
      expect(board).to receive(:send_to_modbus).with(data)
      board.send_to_board(data)
    end
  end

  describe "#send_to_arduino" do
    let(:board) { create(:board, ip: "192.168.1.100") }
    let(:data) { { test: "data" } }

    it "broadcasts data to arduino channel" do
      expect(ActionCable.server).to receive(:broadcast).with(
        "arduino",
        { ip: "192.168.1.100", data: data.to_json }
      )
      board.send_to_arduino(data)
    end
  end

  describe "#send_to_modbus" do
    let(:board) { create(:board, :modbus_tcp) }
    let(:data) { { test: "data" } }

    it "broadcasts data to modbus channel" do
      expect(ActionCable.server).to receive(:broadcast).with("modbus", data)
      board.send_to_modbus(data)
    end
  end

  describe "#set_pins" do
    let!(:board) { create(:board) }
    let!(:device_with_setup) { create(:switch, board: board) }
    let!(:device_without_setup) { create(:virtual_integer, board: board) }

    it "calls setup_pin on devices that respond to it" do
      expect_any_instance_of(Device::Switch).to receive(:setup_pin)
      board.set_pins
    end
  end

  describe "#read_values_from_devices" do
    let!(:board) { create(:board) }
    let!(:readable_device) { create(:switch, board: board, pin: 1) }
    let!(:non_readable_device) { create(:relay, board: board, pin: 2) }

    it "calls get_value_from_board on readable devices" do
      expect_any_instance_of(Device::Switch).to receive(:get_value_from_board)
      board.read_values_from_devices
    end
  end

  describe "#write_values_to_devices" do
    let!(:board) { create(:board) }
    let!(:writable_device) { create(:switch, board: board, pin: 1) }
    let!(:non_writable_device) { create(:relay, board: board, pin: 2) }

    it "calls set_value_to_board on writable devices" do
      expect_any_instance_of(Device::Relay).to receive(:set_value_to_board)
      board.write_values_to_devices
    end
  end

  describe "#chart_data_status" do
    let!(:board) { create(:board) }

    it "returns 0 when connected_at is nil" do
      board.connected_at = nil
      expect(board.chart_data_status).to eq(0)
    end

    it "returns 1 when connected_at is present" do
      board.connected_at = Time.current
      expect(board.chart_data_status).to eq(1)
    end
  end

  describe "#chart_data_signal_strength" do
    let!(:board) { create(:board) }

    it "returns normalized signal strength when signal_strength is present" do
      board.signal_strength = 75
      expect(board.chart_data_signal_strength).to eq(0.75)
    end

    it "returns nil when signal_strength is nil" do
      expect(board.chart_data_signal_strength).to be_nil
    end

    it "returns 0.0 when signal_strength is 0" do
      board.signal_strength = 0
      expect(board.chart_data_signal_strength).to eq(0.0)
    end

    it "returns 1.0 when signal_strength is 100" do
      board.signal_strength = 100
      expect(board.chart_data_signal_strength).to eq(1.0)
    end
  end

  describe "#read_modbus" do
    let!(:board) { create(:board) }
    let!(:device1) { create(:virtual_integer, board: board, holding_register_address: 100, virtual_writable: false) }
    let!(:device2) { create(:virtual_integer, board: board, holding_register_address: 101, virtual_writable: false) }
    let!(:device3) { create(:virtual_integer, board: board, holding_register_address: 103, virtual_writable: false) }

    it "groups devices by consecutive addresses and reads blocks" do
      expect(board).to receive(:read_modbus_block).with([device1, device2])
      expect(board).to receive(:read_modbus_block).with([device3])
      board.read_modbus
    end
  end

  describe "#read_modbus_block" do
    let!(:board) { create(:board, ip: "192.168.1.100", slave_address: 1) }
    let!(:device) { create(:virtual_integer, board: board, holding_register_address: 100) }
    let!(:device2) { create(:virtual_integer, board: board, holding_register_address: 101) }

    it "reads holding registers and sets device values" do
      # Mock ModBus connection
      mock_client = double("ModBus::TCPClient")
      mock_slave = double("slave")

      expect(ModBus::TCPClient).to receive(:connect).with("192.168.1.100", 502).and_yield(mock_client)
      expect(mock_client).to receive(:read_retry_timeout=).with(1)
      expect(mock_client).to receive(:read_retries=).with(1)
      expect(mock_client).to receive(:with_slave).with(1).and_yield(mock_slave)
      expect(mock_slave).to receive(:read_holding_registers).with(100, 2).and_return([123, 456])
      expect(device).to receive(:set).with(123)
      expect(device2).to receive(:set).with(456)
      expect(board).to receive(:connected!)

      board.read_modbus_block([device, device2])
    end

    it "calls disconnected! when connection fails" do
      expect(ModBus::TCPClient).to receive(:connect).and_raise(Errno::ECONNREFUSED)
      expect(board).to receive(:disconnected!)
      board.read_modbus_block([device])
    end
  end

  describe "#write_modbus" do
    let!(:board) { create(:board, ip: "192.168.1.100", slave_address: 1) }
    let!(:device) { create(:virtual_integer, board: board, holding_register_address: 100, value: 50) }

    it "writes device value to modbus register" do
      # Mock ModBus connection
      mock_client = double("ModBus::TCPClient")
      mock_slave = double("slave")

      expect(ModBus::TCPClient).to receive(:connect).with("192.168.1.100", 502).and_yield(mock_client)
      expect(mock_client).to receive(:read_retry_timeout=).with(1)
      expect(mock_client).to receive(:read_retries=).with(1)
      expect(mock_client).to receive(:with_slave).with(1).and_yield(mock_slave)
      expect(mock_slave).to receive(:read_holding_register).with(100).and_return(25)
      expect(mock_slave).to receive(:write_single_register).with(100, 50)
      expect(board).to receive(:connected!)

      board.write_modbus(device)
    end

    it "does not raise error when connection fails" do
      expect(ModBus::TCPClient).to receive(:connect).and_raise(Errno::ECONNREFUSED)
      expect { board.write_modbus(device) }.not_to raise_error
    end
  end

  describe "#clear_logs" do
    let!(:board) { create(:board, days_to_preserve_logs: 7) }
    let!(:old_log) { create(:board_log, board: board, created_at: 10.days.ago) }
    let!(:recent_log) { create(:board_log, board: board, created_at: 1.day.ago) }

    it "deletes logs older than days_to_preserve_logs" do
      expect { board.clear_logs }.to change { board.board_logs.count }.by(-1)
      expect(board.board_logs).to include(recent_log)
      expect(board.board_logs).not_to include(old_log)
    end
  end

  describe "#log_board_log" do
    let!(:board) { create(:board) }

    it "creates a new board log when connected_at changes from nil to present" do
      expect { board.update!(connected_at: Time.current) }.to change { board.reload.board_logs.count }.by(1)
    end

    it "creates a new board log when connected_at changes from present to nil" do
      board.update!(connected_at: Time.current)
      expect { board.update!(connected_at: nil) }.to change { board.reload.board_logs.count }.by(1)
    end

    it "creates a new board log when signal_strength changes" do
      expect { board.update!(signal_strength: 75) }.to change { board.reload.board_logs.count }.by(1)
    end

    it "creates a new board log when ssid changes" do
      expect { board.update!(ssid: "NewWiFi") }.to change { board.reload.board_logs.count }.by(1)
    end

    it "does not create a new board log when no relevant attributes change" do
      expect { board.update!(name: "New Name") }.not_to change { board.reload.board_logs.count }
    end
  end
end