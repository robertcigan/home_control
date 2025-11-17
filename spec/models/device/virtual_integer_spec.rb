require "rails_helper"

RSpec.describe Device::VirtualInteger, type: :model do
  let(:virtual_integer) { create(:virtual_integer) }

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:device_type) }
    it { should validate_uniqueness_of(:pin).scoped_to(:board_id).allow_nil }
  end

  describe "associations" do
    it { should have_many(:device_logs).dependent(:delete_all) }
    it { should have_many(:programs_devices).dependent(:destroy) }
    it { should have_many(:programs).through(:programs_devices) }
    it { should have_many(:widgets).dependent(:destroy) }
    it { should belong_to(:board).optional }
  end

  describe "#set" do
    it "updates the value" do
      virtual_integer.update!(value_integer: 0)
      expect { virtual_integer.set(100) }.to change { virtual_integer.reload.value_integer }.from(0).to(100)
    end
  end

  describe "#status" do
    it "returns the current value" do
      virtual_integer.update!(value_integer: 0)
      expect(virtual_integer.status).to eq(0)
      virtual_integer.value_integer = 100
      expect(virtual_integer.status).to eq(100)
    end
  end

  describe "#value" do
    it "returns the integer value" do
      virtual_integer.update!(value_integer: 0)
      expect(virtual_integer.value).to eq(0)
      virtual_integer.value_integer = 100
      expect(virtual_integer.value).to eq(100)
    end
  end

  describe "#value=" do
    it "sets the integer value" do
      virtual_integer.value = 100
      expect(virtual_integer.value_integer).to eq(100)
    end
  end

  describe "#value_attribute" do
    it "returns :value_integer" do
      expect(virtual_integer.value_attribute).to eq(:value_integer)
    end
  end

  describe "#writable?" do
    it "returns true with modbus_tcp board and virtual_writable true" do
      virtual_integer = create(:virtual_integer, :modbus_writable)
      expect(virtual_integer.writable?).to be true
    end

    it "returns false with non-modbus_tcp board" do
      board = create(:board)
      virtual_integer = create(:virtual_integer, board: board, virtual_writable: true)
      expect(virtual_integer.writable?).to be false
    end

    it "returns false with virtual_writable false" do
      virtual_integer = create(:virtual_integer, :modbus_readable)
      expect(virtual_integer.writable?).to be false
    end

    it "returns false without board" do
      virtual_integer = create(:virtual_integer, board: nil)
      expect(virtual_integer.writable?).to be false
    end
  end

  describe "#set_value_to_board" do
    it "sends device_id to board when writable" do
      virtual_integer = create(:virtual_integer, :modbus_writable)
      expect(virtual_integer.board).to receive(:send_to_board).with({ device_id: virtual_integer.id })
      virtual_integer.set_value_to_board
    end
  end

  describe "#toggle?" do
    it "returns false (inherited from Device)" do
      expect(virtual_integer.toggle?).to be false
    end
  end

  describe "#readable?" do
    it "returns false (inherited from Device)" do
      expect(virtual_integer.readable?).to be false
    end
  end

  describe "#poll?" do
    it "returns false (inherited from Device)" do
      expect(virtual_integer.poll?).to be false
    end
  end

  describe "#to_s" do
    it "returns the device name" do
      virtual_integer.name = "Test Virtual Integer"
      expect(virtual_integer.to_s).to eq("Test Virtual Integer")
    end
  end

  describe "#json_data" do
    it "includes status, updated, value, and indication" do
      virtual_integer.value_integer = 100
      virtual_integer.last_change = Time.current
      json_data = virtual_integer.json_data

      expect(json_data).to include(:status, :updated, :value, :indication)
    end
  end

  describe "#detect_change" do
    it "calls set_value_to_board when value_integer changes and writable" do
      virtual_integer = create(:virtual_integer, :modbus_writable, value_integer: 0)
      expect(virtual_integer).to receive(:set_value_to_board)
      virtual_integer.update!(value_integer: 100)
    end

    it "calls trigger_programs when value_integer changes and writable" do
      virtual_integer = create(:virtual_integer, :modbus_writable, value_integer: 0)
      expect(virtual_integer).to receive(:trigger_programs)
      virtual_integer.update!(value_integer: 100)
    end

    it "does not call set_value_to_board when value_integer changes and not writable" do
      virtual_integer.update!(value_integer: 0)
      expect(virtual_integer).not_to receive(:set_value_to_board)
      virtual_integer.update!(value_integer: 100)
    end

    it "still calls trigger_programs when value_integer changes and not writable" do
      virtual_integer.update!(value_integer: 0)
      expect(virtual_integer).to receive(:trigger_programs)
      virtual_integer.update!(value_integer: 100)
    end
  end

  describe "#reset_pins" do
    it "does nothing (overridden from Device)" do
      expect { virtual_integer.send(:reset_pins) }.not_to raise_error
    end
  end

  describe "#log_device_log" do
    it "creates device log when value_integer changes" do
      virtual_integer.update!(value_integer: 0)
      expect { virtual_integer.update!(value_integer: 100) }.to change { virtual_integer.device_logs.count }.by(1)
      log = virtual_integer.device_logs.last
      expect(log.value_integer).to eq(100)
    end

    it "updates last_change when value_integer changes" do
      virtual_integer.update!(value_integer: 0)
      expect { virtual_integer.update!(value_integer: 100) }.to change { virtual_integer.reload.last_change }
    end

    it "does not create log when value_integer does not change" do
      expect { virtual_integer.update!(name: "New Name") }.not_to change { virtual_integer.device_logs.count }
    end
  end

  describe "callbacks" do
    describe "after_commit :detect_change" do
      it "calls set_value_to_board when value_integer changes and writable" do
        virtual_integer = create(:virtual_integer, :modbus_writable, value_integer: 0)
        expect(virtual_integer).to receive(:set_value_to_board)
        virtual_integer.update!(value_integer: 100)
      end

      it "triggers programs when value_integer changes and writable" do
        virtual_integer = create(:virtual_integer, :modbus_writable, value_integer: 0)
        expect(virtual_integer).to receive(:trigger_programs)
        virtual_integer.update!(value_integer: 100)
      end

      it "does not call set_value_to_board when value_integer changes and not writable" do
        virtual_integer.update!(value_integer: 0)
        expect(virtual_integer).not_to receive(:set_value_to_board)
        virtual_integer.update!(value_integer: 100)
      end

      it "still triggers programs when value_integer changes and not writable" do
        virtual_integer.update!(value_integer: 0)
        expect(virtual_integer).to receive(:trigger_programs)
        virtual_integer.update!(value_integer: 100)
      end

      it "does not call set_value_to_board when other attributes change" do
        expect(virtual_integer).not_to receive(:set_value_to_board)
        virtual_integer.update!(name: "New Name")
      end
    end
  end
end