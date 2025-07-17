require "rails_helper"

RSpec.describe Device::VirtualDecimal, type: :model do
  let(:virtual_decimal) { create(:virtual_decimal) }

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
      virtual_decimal.update!(value_decimal: 0.0)
      expect { virtual_decimal.set(12.5) }.to change { virtual_decimal.reload.value_decimal }.from(0.0).to(12.5)
    end
  end

  describe "#status" do
    it "returns the current value" do
      virtual_decimal.update!(value_decimal: 0.0)
      expect(virtual_decimal.status).to eq(0.0)
      virtual_decimal.value_decimal = 12.5
      expect(virtual_decimal.status).to eq(12.5)
    end
  end

  describe "#value" do
    it "returns the decimal value" do
      virtual_decimal.update!(value_decimal: 0.0)
      expect(virtual_decimal.value).to eq(0.0)
      virtual_decimal.value_decimal = 12.5
      expect(virtual_decimal.value).to eq(12.5)
    end
  end

  describe "#value=" do
    it "sets the decimal value" do
      virtual_decimal.value = 12.5
      expect(virtual_decimal.value_decimal).to eq(12.5)
    end
  end

  describe "#value_attribute" do
    it "returns :value_decimal" do
      expect(virtual_decimal.value_attribute).to eq(:value_decimal)
    end
  end

  describe "#writable?" do
    it "returns true with modbus_tcp board and virtual_writable true" do
      virtual_decimal = create(:virtual_decimal, :modbus_writable)
      expect(virtual_decimal.writable?).to be true
    end

    it "returns false with non-modbus_tcp board" do
      board = create(:board)
      virtual_decimal = create(:virtual_decimal, board: board, virtual_writable: true)
      expect(virtual_decimal.writable?).to be false
    end

    it "returns false with virtual_writable false" do
      virtual_decimal = create(:virtual_decimal, :modbus_readable)
      expect(virtual_decimal.writable?).to be false
    end

    it "returns false without board" do
      virtual_decimal = create(:virtual_decimal, board: nil)
      expect(virtual_decimal.writable?).to be false
    end
  end

  describe "#set_value_to_board" do
    it "sends device_id to board when writable" do
      virtual_decimal = create(:virtual_decimal, :modbus_writable)
      expect(virtual_decimal.board).to receive(:send_to_board).with({ device_id: virtual_decimal.id })
      virtual_decimal.set_value_to_board
    end
  end

  describe "#toggle?" do
    it "returns false (inherited from Device)" do
      expect(virtual_decimal.toggle?).to be false
    end
  end

  describe "#readable?" do
    it "returns false (inherited from Device)" do
      expect(virtual_decimal.readable?).to be false
    end
  end

  describe "#poll?" do
    it "returns false (inherited from Device)" do
      expect(virtual_decimal.poll?).to be false
    end
  end

  describe "#to_s" do
    it "returns the device name" do
      virtual_decimal.name = "Test Virtual Decimal"
      expect(virtual_decimal.to_s).to eq("Test Virtual Decimal")
    end
  end

  describe "#json_data" do
    it "includes status, updated, value, and indication" do
      virtual_decimal.value_decimal = 12.5
      virtual_decimal.last_change = Time.current
      json_data = virtual_decimal.json_data

      expect(json_data).to include(:status, :updated, :value, :indication)
    end
  end

  describe "#detect_change" do
    it "calls set_value_to_board when value_decimal changes and writable" do
      virtual_decimal = create(:virtual_decimal, :modbus_writable, value_decimal: 0.0)
      expect(virtual_decimal).to receive(:set_value_to_board)
      virtual_decimal.update!(value_decimal: 12.5)
    end

    it "calls trigger_programs when value_decimal changes and writable" do
      virtual_decimal = create(:virtual_decimal, :modbus_writable, value_decimal: 0.0)
      expect(virtual_decimal).to receive(:trigger_programs)
      virtual_decimal.update!(value_decimal: 12.5)
    end

    it "does not call set_value_to_board when value_decimal changes and not writable" do
      virtual_decimal.update!(value_decimal: 0.0)
      expect(virtual_decimal).not_to receive(:set_value_to_board)
      virtual_decimal.update!(value_decimal: 12.5)
    end

    it "still calls trigger_programs when value_decimal changes and not writable" do
      virtual_decimal.update!(value_decimal: 0.0)
      expect(virtual_decimal).to receive(:trigger_programs)
      virtual_decimal.update!(value_decimal: 12.5)
    end
  end

  describe "#reset_pins" do
    it "does nothing (overridden from Device)" do
      expect { virtual_decimal.send(:reset_pins) }.not_to raise_error
    end
  end

  describe "#log_device_log" do
    it "creates device log when value_decimal changes" do
      virtual_decimal.update!(value_decimal: 0.0)
      expect { virtual_decimal.update!(value_decimal: 12.5) }.to change { virtual_decimal.device_logs.count }.by(1)
      log = virtual_decimal.device_logs.last
      expect(log.value_decimal).to eq(12.5)
    end

    it "updates last_change when value_decimal changes" do
      virtual_decimal.update!(value_decimal: 0.0)
      expect { virtual_decimal.update!(value_decimal: 12.5) }.to change { virtual_decimal.reload.last_change }
    end

    it "does not create log when value_decimal does not change" do
      expect { virtual_decimal.update!(name: "New Name") }.not_to change { virtual_decimal.device_logs.count }
    end
  end

  describe "callbacks" do
    describe "after_commit :detect_change" do
      it "calls set_value_to_board when value_decimal changes and writable" do
        virtual_decimal = create(:virtual_decimal, :modbus_writable, value_decimal: 0.0)
        expect(virtual_decimal).to receive(:set_value_to_board)
        virtual_decimal.update!(value_decimal: 12.5)
      end

      it "triggers programs when value_decimal changes and writable" do
        virtual_decimal = create(:virtual_decimal, :modbus_writable, value_decimal: 0.0)
        expect(virtual_decimal).to receive(:trigger_programs)
        virtual_decimal.update!(value_decimal: 12.5)
      end

      it "does not call set_value_to_board when value_decimal changes and not writable" do
        virtual_decimal.update!(value_decimal: 0.0)
        expect(virtual_decimal).not_to receive(:set_value_to_board)
        virtual_decimal.update!(value_decimal: 12.5)
      end

      it "still triggers programs when value_decimal changes and not writable" do
        virtual_decimal.update!(value_decimal: 0.0)
        expect(virtual_decimal).to receive(:trigger_programs)
        virtual_decimal.update!(value_decimal: 12.5)
      end

      it "does not call set_value_to_board when other attributes change" do
        expect(virtual_decimal).not_to receive(:set_value_to_board)
        virtual_decimal.update!(name: "New Name")
      end
    end
  end
end