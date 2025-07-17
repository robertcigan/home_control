require "rails_helper"

RSpec.describe Device::Switch, type: :model do
  let!(:switch) { create(:switch) }

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
      switch.update!(value_boolean: false)
      expect { switch.set(true) }.to change { switch.reload.value_boolean }.from(false).to(true)
    end
  end

  describe "#status" do
    it "returns the current value" do
      switch.update!(value_boolean: false)
      expect(switch.status).to eq(false)
      switch.value_boolean = true
      expect(switch.status).to eq(true)
    end
  end

  describe "#indication" do
    it "returns 'on' when value is true" do
      switch.value_boolean = true
      expect(switch.indication).to eq("on")
    end

    it "returns 'off' when value is false" do
      switch.value_boolean = false
      expect(switch.indication).to eq("off")
    end
  end

  describe "#value" do
    it "returns the boolean value" do
      switch.update!(value_boolean: false)
      expect(switch.value).to eq(false)
      switch.value_boolean = true
      expect(switch.value).to eq(true)
    end
  end

  describe "#value=" do
    it "sets the boolean value" do
      switch.value = true
      expect(switch.value_boolean).to eq(true)
    end
  end

  describe "#setup_pin" do
    it "sends add command to board with correct parameters" do
      expect(switch).to receive(:send_to_board).with(
        add: { id: switch.id, type: "switch", pin: switch.pin, poll: switch.poll || 250, inverted: switch.inverted }
      )
      switch.setup_pin
    end
  end

  describe "#readable?" do
    it "returns true" do
      expect(switch.readable?).to be true
    end
  end

  describe "#poll?" do
    it "returns true" do
      expect(switch.poll?).to be true
    end
  end

  describe "#get_value_from_board" do
    it "sends read command to board with correct parameters" do
      expect(switch).to receive(:send_to_board).with(read: { id: switch.id })
      switch.get_value_from_board
    end
  end

  describe "#value_attribute" do
    it "returns :value_boolean" do
      expect(switch.value_attribute).to eq(:value_boolean)
    end
  end

  describe "#writable?" do
    it "returns false (inherited from Device)" do
      expect(switch.writable?).to be false
    end
  end

  describe "#toggle?" do
    it "returns false (inherited from Device)" do
      expect(switch.toggle?).to be false
    end
  end

  describe "#to_s" do
    it "returns the device name" do
      switch.name = "Test Switch"
      expect(switch.to_s).to eq("Test Switch")
    end
  end

  describe "#json_data" do
    it "includes status, updated, value, and indication" do
      switch.value_boolean = true
      switch.last_change = Time.current
      json_data = switch.json_data

      expect(json_data).to include(:status, :updated, :value, :indication)
    end
  end

  describe "#detect_change" do
    it "calls trigger_programs when value_boolean changes" do
      expect(switch).to receive(:trigger_programs)
      switch.update!(value_boolean: true)
    end
  end

  describe "#log_device_log" do
    it "creates device log when value_boolean changes" do
      switch.update!(value_boolean: false)
      time = Time.current
      Timecop.freeze(time) do
        expect { switch.update!(value_boolean: true) }.to change { switch.device_logs.count }.by(1)
        log = switch.device_logs.last
        expect(log.value_boolean).to eq(true)
      end
    end

    it "updates last_change when value_boolean changes" do
      switch.update!(value_boolean: false)
      time = Time.current
      Timecop.freeze(time) do
        expect { switch.update!(value_boolean: true) }.to change { switch.reload.last_change }
      end
    end

    it "does not create log when value_boolean does not change" do
      time = Time.current
      Timecop.freeze(time) do
        expect { switch.update!(name: "New Name") }.not_to change { switch.device_logs.count }
      end
    end
  end

  describe "callbacks" do
    describe "after_commit :detect_change" do
      it "triggers programs when value_boolean changes" do
        switch.update!(value_boolean: false)
        expect(switch).to receive(:trigger_programs)
        switch.update!(value_boolean: true)
      end

      it "does not trigger programs when other attributes change" do
        expect(switch).not_to receive(:trigger_programs)
        switch.update!(name: "New Name")
      end
    end
  end
end