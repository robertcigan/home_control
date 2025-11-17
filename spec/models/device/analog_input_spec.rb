require "rails_helper"

RSpec.describe Device::AnalogInput, type: :model do
  let!(:analog_input) { create(:analog_input) }

  describe "validations" do
    it { should validate_presence_of(:board) }
  end

  describe "inherited validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:device_type) }
    it { should validate_uniqueness_of(:pin).scoped_to(:board_id).allow_nil }
  end

  describe "inherited associations" do
    it { should have_many(:device_logs).dependent(:delete_all) }
    it { should have_many(:programs_devices).dependent(:destroy) }
    it { should have_many(:programs).through(:programs_devices) }
    it { should have_many(:widgets).dependent(:destroy) }
  end

  describe "#set" do
    it "updates the value" do
      analog_input.update!(value_decimal: 0.0)
      expect { analog_input.set(12.5) }.to change { analog_input.reload.value_decimal }.from(0.0).to(12.5)
    end
  end

  describe "#status" do
    it "returns the current value" do
      analog_input.update!(value_decimal: 0.0)
      expect(analog_input.status).to eq(0.0)
      analog_input.value_decimal = 12.5
      expect(analog_input.status).to eq(12.5)
    end
  end

  describe "#value" do
    it "returns the decimal value" do
      analog_input.update!(value_decimal: 0.0)
      expect(analog_input.value).to eq(0.0)
      analog_input.value_decimal = 12.5
      expect(analog_input.value).to eq(12.5)
    end
  end

  describe "#value=" do
    it "sets the decimal value" do
      analog_input.value = 12.5
      expect(analog_input.value_decimal).to eq(12.5)
    end
  end

  describe "#setup_pin" do
    it "sends add command to board with correct parameters" do
      expect(analog_input).to receive(:send_to_board).with(
        add: { id: analog_input.id, type: "analog_input", pin: analog_input.pin, poll: analog_input.poll || 5000 }
      )
      analog_input.setup_pin
    end
  end

  describe "#readable?" do
    it "returns true" do
      expect(analog_input.readable?).to be true
    end
  end

  describe "#poll?" do
    it "returns true" do
      expect(analog_input.poll?).to be true
    end
  end

  describe "#get_value_from_board" do
    it "sends read command to board with correct parameters" do
      expect(analog_input).to receive(:send_to_board).with(read: { id: analog_input.id })
      analog_input.get_value_from_board
    end
  end

  describe "#value_attribute" do
    it "returns :value_decimal" do
      expect(analog_input.value_attribute).to eq(:value_decimal)
    end
  end

  describe "#writable?" do
    it "returns false (inherited from Device)" do
      expect(analog_input.writable?).to be false
    end
  end

  describe "#toggle?" do
    it "returns false (inherited from Device)" do
      expect(analog_input.toggle?).to be false
    end
  end

  describe "#to_s" do
    it "returns the device name" do
      analog_input.name = "Test Analog Input"
      expect(analog_input.to_s).to eq("Test Analog Input")
    end
  end

  describe "#json_data" do
    it "includes status, updated, value, and indication" do
      analog_input.value_decimal = 12.5
      analog_input.last_change = Time.current
      json_data = analog_input.json_data

      expect(json_data).to include(:status, :updated, :value, :indication)
    end
  end

  describe "#indication" do
    it "includes unit in indication when unit is present" do
      analog_input.update!(unit: "V", value_decimal: 12.5)
      expect(analog_input.indication).to eq("12.5V")
    end

    it "returns value without unit when unit is nil" do
      analog_input.update!(unit: nil, value_decimal: 12.5)
      expect(analog_input.indication).to eq(12.5)
    end
  end

  describe "#detect_change" do
    it "calls trigger_programs when value_decimal changes" do
      analog_input.update!(value_decimal: 0.0)
      expect(analog_input).to receive(:trigger_programs)
      analog_input.update!(value_decimal: 12.5)
    end
  end

  describe "#log_device_log" do
    it "creates device log when value_decimal changes" do
      analog_input.update!(value_decimal: 0.0)
      expect {
        analog_input.update!(value_decimal: 12.5)
      }.to change { analog_input.device_logs.count }.by(1)

      log = analog_input.device_logs.last
      expect(log.value_decimal).to eq(12.5)
    end

    it "updates last_change when value_decimal changes" do
      analog_input.update!(value_decimal: 0.0)
      expect {
        analog_input.update!(value_decimal: 12.5)
      }.to change { analog_input.reload.last_change }
    end

    it "does not create log when value_decimal does not change" do
      expect {
        analog_input.update!(name: "New Name")
      }.not_to change { analog_input.device_logs.count }
    end
  end

  describe "callbacks" do
    describe "after_commit :detect_change" do
      it "triggers programs when value_decimal changes" do
        analog_input.update!(value_decimal: 0.0)
        expect(analog_input).to receive(:trigger_programs)
        analog_input.update!(value_decimal: 12.5)
      end

      it "does not trigger programs when other attributes change" do
        expect(analog_input).not_to receive(:trigger_programs)
        analog_input.update!(name: "New Name")
      end
    end
  end
end