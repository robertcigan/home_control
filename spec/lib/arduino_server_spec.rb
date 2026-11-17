require "rails_helper"
require "arduino_server"

RSpec.describe ArduinoServer do
  before do
    ArduinoMessenger.class_variable_set(:@@connected_clients, [])
  end

  describe ".run_exclusively" do
    it "runs the job and releases the lock" do
      lock = Mutex.new
      ran = false
      expect(described_class.run_exclusively("job", lock) { ran = true }).to be true
      expect(ran).to be true
      expect(lock).not_to be_locked
    end

    it "skips the job while the previous run still holds the lock" do
      lock = Mutex.new
      ran = false
      lock.lock # previous run still in progress
      expect(described_class.run_exclusively("job", lock) { ran = true }).to be false
      expect(ran).to be false
      expect(lock).to be_locked
      lock.unlock
    end

    it "logs an error instead of raising and releases the lock" do
      lock = Mutex.new
      expect { described_class.run_exclusively("job", lock) { raise "boom" } }.not_to raise_error
      expect(lock).not_to be_locked
    end
  end

  describe ".each_safely" do
    it "continues with the remaining records when one of them fails" do
      processed = []
      described_class.each_safely([1, 2, 3], "job") do |n|
        raise "boom" if n == 2
        processed << n
      end
      expect(processed).to eq([1, 3])
    end
  end

  describe ".every" do
    it "never runs the same job concurrently and survives job errors" do
      runs = 0
      running = 0
      max_running = 0
      counter_lock = Mutex.new

      EM.run do
        described_class.every(0.05, "slow job") do
          counter_lock.synchronize do
            runs += 1
            running += 1
            max_running = [max_running, running].max
          end
          sleep 0.2
          counter_lock.synchronize { running -= 1 }
          raise "boom"
        end
        EM.add_timer(0.9) { EM.stop }
      end

      expect(runs).to be >= 2
      expect(max_running).to eq(1)
    end

    it "returns a tick that triggers a run immediately" do
      ran = false
      EM.run do
        tick = described_class.every(60, "job", defer: false) { ran = true }
        tick.call
        EM.stop
      end
      expect(ran).to be true
    end
  end

  describe ".dispatch_arduino_command" do
    let(:connection) { instance_double(ArduinoMessenger, ip: "192.168.1.77") }

    before do
      ArduinoMessenger.class_variable_set(:@@connected_clients, [connection])
    end

    it "sends the command to the connection with the matching IP" do
      expect(connection).to receive(:send_command).with("{\"ping\":true}")
      described_class.dispatch_arduino_command("message" => { "ip" => "192.168.1.77", "data" => "{\"ping\":true}" })
    end

    it "does nothing when no board with that IP is connected" do
      expect(connection).not_to receive(:send_command)
      described_class.dispatch_arduino_command("message" => { "ip" => "10.0.0.1", "data" => "{}" })
    end

    it "ignores malformed messages" do
      expect(connection).not_to receive(:send_command)
      expect { described_class.dispatch_arduino_command(nil) }.not_to raise_error
      expect { described_class.dispatch_arduino_command("message" => 1) }.not_to raise_error
    end
  end

  describe ".close_timed_out_connections" do
    it "closes only connections silent for longer than the timeout" do
      stale = instance_double(ArduinoMessenger, ip: "192.168.1.1", received_timestamp: 31.seconds.ago)
      fresh = instance_double(ArduinoMessenger, ip: "192.168.1.2", received_timestamp: 5.seconds.ago)
      ArduinoMessenger.class_variable_set(:@@connected_clients, [stale, fresh])

      expect(stale).to receive(:close_connection)
      expect(fresh).not_to receive(:close_connection)
      described_class.close_timed_out_connections
    end
  end

  describe ".write_modbus_device" do
    it "writes the device value through its board" do
      board = create(:board, board_type: Board::BoardType::MODBUS_TCP, slave_address: 1, data_read_interval: 10)
      device = create(:virtual_integer, board: board, holding_register_address: 1)
      expect_any_instance_of(Board).to receive(:write_modbus).with(device)
      described_class.write_modbus_device(device.id)
    end

    it "does nothing for an unknown device" do
      expect { described_class.write_modbus_device(0) }.not_to raise_error
    end
  end
end
