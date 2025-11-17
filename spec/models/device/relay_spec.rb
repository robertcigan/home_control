require "rails_helper"

RSpec.describe Device::Relay, type: :model do
  let!(:relay) { create(:relay) }

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
      relay.update!(value_boolean: false)
      expect { relay.set(true) }.to change { relay.reload.value_boolean }.from(false).to(true)
    end
  end

  describe "#status" do
    it "returns the current value" do
      relay.update!(value_boolean: false)
      expect(relay.status).to eq(false)
      relay.value_boolean = true
      expect(relay.status).to eq(true)
    end
  end

  describe "#indication" do
    it "returns 'on' when value is true" do
      relay.value_boolean = true
      expect(relay.indication).to eq("on")
    end

    it "returns 'off' when value is false" do
      relay.value_boolean = false
      expect(relay.indication).to eq("off")
    end
  end

  describe "#value" do
    it "returns the boolean value" do
      relay.update!(value_boolean: false)
      expect(relay.value).to eq(false)
      relay.value_boolean = true
      expect(relay.value).to eq(true)
    end
  end

  describe "#value=" do
    it "sets the boolean value" do
      relay.value = true
      expect(relay.value_boolean).to eq(true)
    end
  end

  describe "#setup_pin" do
    it "sends add command to board with correct parameters" do
      expect(relay).to receive(:send_to_board).with({add: { id: relay.id, type: "relay", pin: relay.pin, inverted: false, default_value: relay.value }})
      expect(relay).to receive(:send_to_board).with({write: { id: relay.id, type: "relay", value: relay.value }})
      relay.setup_pin
    end

    it "calls set_value_to_board" do
      expect(relay).to receive(:set_value_to_board)
      relay.setup_pin
    end
  end

  describe "#writable?" do
    it "returns true" do
      expect(relay.writable?).to be true
    end
  end

  describe "#set_value_to_board" do
    it "sends write command to board with correct parameters" do
      expect(relay).to receive(:send_to_board).with({write: { id: relay.id, type: "relay", value: relay.value }})
      relay.set_value_to_board
    end
  end

  describe "#toggle?" do
    it "returns true" do
      expect(relay.toggle?).to be true
    end
  end

  describe "#value_attribute" do
    it "returns :value_boolean" do
      expect(relay.value_attribute).to eq(:value_boolean)
    end
  end

  describe "#readable?" do
    it "returns false (inherited from Device)" do
      expect(relay.readable?).to be false
    end
  end

  describe "#poll?" do
    it "returns false (inherited from Device)" do
      expect(relay.poll?).to be false
    end
  end

  describe "#to_s" do
    it "returns the device name" do
      relay.name = "Test Relay"
      expect(relay.to_s).to eq("Test Relay")
    end
  end

  describe "#json_data" do
    it "includes status, updated, value, and indication" do
      relay.value_boolean = true
      relay.last_change = Time.current
      json_data = relay.json_data

      expect(json_data).to include(:status, :updated, :value, :indication)
    end
  end

  describe "#detect_change" do
    it "calls set_value_to_board when value_boolean changes" do
      expect(relay).to receive(:set_value_to_board)
      relay.update!(value_boolean: true)
    end

    it "calls trigger_programs when value_boolean changes" do
      expect(relay).to receive(:trigger_programs)
      relay.update!(value_boolean: true)
    end
  end

  describe "#log_device_log" do
    it "creates device log when value_boolean changes" do
      relay.update!(value_boolean: false)
      time = Time.current
      Timecop.freeze(time) do
        expect { relay.update!(value_boolean: true) }.to change { relay.device_logs.count }.by(1)
        log = relay.device_logs.last
        expect(log.value_boolean).to eq(true)
      end
    end

    it "updates last_change when value_boolean changes" do
      relay.update!(value_boolean: false)
      time = Time.current
      Timecop.freeze(time) do
        expect { relay.update!(value_boolean: true) }.to change { relay.reload.last_change }
      end
    end

    it "does not create log when value_boolean does not change" do
      time = Time.current
      Timecop.freeze(time) do
        expect { relay.update!(name: "New Name") }.not_to change { relay.device_logs.count }
      end
    end
  end

  describe "callbacks" do
    describe "after_commit :detect_change" do
      it "calls set_value_to_board when value_boolean changes" do
        relay.update!(value_boolean: false)
        expect(relay).to receive(:set_value_to_board)
        relay.update!(value_boolean: true)
      end

      it "triggers programs when value_boolean changes" do
        relay.update!(value_boolean: false)
        expect(relay).to receive(:trigger_programs)
        relay.update!(value_boolean: true)
      end

      it "does not call set_value_to_board when other attributes change" do
        expect(relay).not_to receive(:set_value_to_board)
        relay.update!(name: "New Name")
      end
    end
  end
end