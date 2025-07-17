require "rails_helper"

RSpec.describe Device::VirtualBoolean, type: :model do
  let(:virtual_boolean) { create(:virtual_boolean) }

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
      virtual_boolean.update!(value_boolean: false)
      expect { virtual_boolean.set(true) }.to change { virtual_boolean.reload.value_boolean }.from(false).to(true)
    end
  end

  describe "#status" do
    it "returns the current value" do
      virtual_boolean.update!(value_boolean: false)
      expect(virtual_boolean.status).to eq(false)
      virtual_boolean.value_boolean = true
      expect(virtual_boolean.status).to eq(true)
    end
  end

  describe "#indication" do
    it "returns string representation of boolean value" do
      virtual_boolean.value_boolean = true
      expect(virtual_boolean.indication).to eq("true")
      virtual_boolean.value_boolean = false
      expect(virtual_boolean.indication).to eq("false")
    end
  end

  describe "#value" do
    it "returns the boolean value" do
      virtual_boolean.update!(value_boolean: false)
      expect(virtual_boolean.value).to eq(false)
      virtual_boolean.value_boolean = true
      expect(virtual_boolean.value).to eq(true)
    end
  end

  describe "#value=" do
    it "sets the boolean value" do
      virtual_boolean.value = true
      expect(virtual_boolean.value_boolean).to eq(true)
    end
  end

  describe "#writable?" do
    it "returns true with modbus_tcp board and virtual_writable true" do
      virtual_boolean = create(:virtual_boolean, :modbus_writable)
      expect(virtual_boolean.writable?).to be true
    end

    it "returns false with non-modbus_tcp board" do
      board = create(:board)
      virtual_boolean = create(:virtual_boolean, board: board, virtual_writable: true)
      expect(virtual_boolean.writable?).to be false
    end

    it "returns false with virtual_writable false" do
      virtual_boolean = create(:virtual_boolean, :modbus_readable)
      expect(virtual_boolean.writable?).to be false
    end

    it "returns false without board" do
      virtual_boolean = create(:virtual_boolean, board: nil)
      expect(virtual_boolean.writable?).to be false
    end
  end

  describe "#set_value_to_board" do
    it "sends device_id to board when writable" do
      virtual_boolean = create(:virtual_boolean, :modbus_writable)
      expect(virtual_boolean.board).to receive(:send_to_board).with({ device_id: virtual_boolean.id })
      virtual_boolean.set_value_to_board
    end
  end

  describe "#toggle?" do
    it "returns true" do
      expect(virtual_boolean.toggle?).to be true
    end
  end

  describe "#value_attribute" do
    it "returns :value_boolean" do
      expect(virtual_boolean.value_attribute).to eq(:value_boolean)
    end
  end

  describe "#readable?" do
    it "returns false (inherited from Device)" do
      expect(virtual_boolean.readable?).to be false
    end
  end

  describe "#poll?" do
    it "returns false (inherited from Device)" do
      expect(virtual_boolean.poll?).to be false
    end
  end

  describe "#to_s" do
    it "returns the device name" do
      virtual_boolean.name = "Test Virtual Boolean"
      expect(virtual_boolean.to_s).to eq("Test Virtual Boolean")
    end
  end

  describe "#json_data" do
    it "includes status, updated, value, and indication" do
      virtual_boolean.value_boolean = true
      virtual_boolean.last_change = Time.current
      json_data = virtual_boolean.json_data

      expect(json_data).to include(:status, :updated, :value, :indication)
    end
  end

  describe "#detect_change" do
    it "calls set_value_to_board when value_boolean changes and writable" do
      virtual_boolean = create(:virtual_boolean, :modbus_writable, value_boolean: false)
      expect(virtual_boolean).to receive(:set_value_to_board)
      virtual_boolean.update!(value_boolean: true)
    end

    it "calls trigger_programs when value_boolean changes and writable" do
      virtual_boolean = create(:virtual_boolean, :modbus_writable, value_boolean: false)
      expect(virtual_boolean).to receive(:trigger_programs)
      virtual_boolean.update!(value_boolean: true)
    end

    it "does not call set_value_to_board when value_boolean changes and not writable" do
      virtual_boolean.update!(value_boolean: false)
      expect(virtual_boolean).not_to receive(:set_value_to_board)
      virtual_boolean.update!(value_boolean: true)
    end

    it "still calls trigger_programs when value_boolean changes and not writable" do
      virtual_boolean.update!(value_boolean: false)
      expect(virtual_boolean).to receive(:trigger_programs)
      virtual_boolean.update!(value_boolean: true)
    end
  end

  describe "#reset_pins" do
    it "does nothing (overridden from Device)" do
      expect { virtual_boolean.send(:reset_pins) }.not_to raise_error
    end
  end

  describe "#log_device_log" do
    it "creates device log when value_boolean changes" do
      virtual_boolean.update!(value_boolean: false)
      expect { virtual_boolean.update!(value_boolean: true) }.to change { virtual_boolean.device_logs.count }.by(1)
      log = virtual_boolean.device_logs.last
      expect(log.value_boolean).to eq(true)
    end

    it "updates last_change when value_boolean changes" do
      virtual_boolean.update!(value_boolean: false)
      expect { virtual_boolean.update!(value_boolean: true) }.to change { virtual_boolean.reload.last_change }
    end

    it "does not create log when value_boolean does not change" do
      expect { virtual_boolean.update!(name: "New Name") }.not_to change { virtual_boolean.device_logs.count }
    end
  end

  describe "callbacks" do
    describe "after_commit :detect_change" do
      it "calls set_value_to_board when value_boolean changes and writable" do
        virtual_boolean = create(:virtual_boolean, :modbus_writable, value_boolean: false)
        expect(virtual_boolean).to receive(:set_value_to_board)
        virtual_boolean.update!(value_boolean: true)
      end

      it "triggers programs when value_boolean changes and writable" do
        virtual_boolean = create(:virtual_boolean, :modbus_writable, value_boolean: false)
        expect(virtual_boolean).to receive(:trigger_programs)
        virtual_boolean.update!(value_boolean: true)
      end

      it "does not call set_value_to_board when value_boolean changes and not writable" do
        virtual_boolean.update!(value_boolean: false)
        expect(virtual_boolean).not_to receive(:set_value_to_board)
        virtual_boolean.update!(value_boolean: true)
      end

      it "still triggers programs when value_boolean changes and not writable" do
        virtual_boolean.update!(value_boolean: false)
        expect(virtual_boolean).to receive(:trigger_programs)
        virtual_boolean.update!(value_boolean: true)
      end

      it "does not call set_value_to_board when other attributes change" do
        expect(virtual_boolean).not_to receive(:set_value_to_board)
        virtual_boolean.update!(name: "New Name")
      end
    end
  end
end
