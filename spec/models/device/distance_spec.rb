require "rails_helper"

RSpec.describe Device::Distance, type: :model do
  let(:distance) { create(:distance) }

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
      distance.update!(value_integer: 0)
      expect { distance.set(150) }.to change { distance.reload.value_integer }.from(0).to(150)
    end
  end

  describe "#status" do
    it "returns the current value" do
      distance.update!(value_integer: 0)
      expect(distance.status).to eq(0)
      distance.value_integer = 150
      expect(distance.status).to eq(150)
    end
  end

  describe "#indication" do
    it "includes unit in indication when unit is present" do
      distance.update!(unit: "mm", value_integer: 150)
      expect(distance.indication).to eq("150mm")
    end

    it "returns value with cm as default unit when unit is nil" do
      distance.update!(unit: nil, value_integer: 150)
      expect(distance.indication).to eq("150cm")
    end
  end

  describe "#value" do
    it "returns the integer value" do
      distance.update!(value_integer: 0)
      expect(distance.value).to eq(0)
      distance.value_integer = 150
      expect(distance.value).to eq(150)
    end
  end

  describe "#value=" do
    it "sets the integer value" do
      distance.value = 150
      expect(distance.value_integer).to eq(150)
    end
  end

  describe "#setup_pin" do
    it "sends add command to board with correct parameters" do
      distance.update!(pin: 5)
      expect(distance).to receive(:send_to_board).with(
        add: { id: distance.id, type: "distance", write_pin: 5, read_pin: 6, poll: distance.poll || 30000 }
      )
      distance.setup_pin
    end
  end

  describe "#readable?" do
    it "returns true" do
      expect(distance.readable?).to be true
    end
  end

  describe "#poll?" do
    it "returns true" do
      expect(distance.poll?).to be true
    end
  end

  describe "#get_value_from_board" do
    it "sends read command to board with correct parameters" do
      expect(distance).to receive(:send_to_board).with(read: { id: distance.id })
      distance.get_value_from_board
    end
  end

  describe "#value_attribute" do
    it "returns :value_integer" do
      expect(distance.value_attribute).to eq(:value_integer)
    end
  end

  describe "#writable?" do
    it "returns false (inherited from Device)" do
      expect(distance.writable?).to be false
    end
  end

  describe "#toggle?" do
    it "returns false (inherited from Device)" do
      expect(distance.toggle?).to be false
    end
  end

  describe "#to_s" do
    it "returns the device name" do
      distance.name = "Test Distance"
      expect(distance.to_s).to eq("Test Distance")
    end
  end

  describe "#json_data" do
    it "includes status, updated, value, and indication" do
      distance.value_integer = 150
      distance.last_change = Time.current
      json_data = distance.json_data

      expect(json_data).to include(:status, :updated, :value, :indication)
    end
  end

  describe "#detect_change" do
    it "calls trigger_programs when value_integer changes" do
      distance.update!(value_integer: 0)
      expect(distance).to receive(:trigger_programs)
      distance.update!(value_integer: 150)
    end
  end

  describe "#log_device_log" do
    it "creates device log when value_integer changes" do
      distance.update!(value_integer: 0)
      time = Time.current
      Timecop.freeze(time) do
        expect { distance.update!(value_integer: 150) }.to change { distance.device_logs.count }.by(1)
        log = distance.device_logs.last
        expect(log.value_integer).to eq(150)
      end
    end

    it "updates last_change when value_integer changes" do
      distance.update!(value_integer: 0)
      time = Time.current
      Timecop.freeze(time) do
        expect { distance.update!(value_integer: 150) }.to change { distance.reload.last_change }
      end
    end

    it "does not create log when value_integer does not change" do
      time = Time.current
      Timecop.freeze(time) do
        expect { distance.update!(name: "New Name") }.not_to change { distance.device_logs.count }
      end
    end
  end

  describe "callbacks" do
    describe "after_commit :detect_change" do
      it "triggers programs when value_integer changes" do
        distance.update!(value_integer: 0)
        expect(distance).to receive(:trigger_programs)
        distance.update!(value_integer: 150)
      end

      it "does not trigger programs when other attributes change" do
        expect(distance).not_to receive(:trigger_programs)
        distance.update!(name: "New Name")
      end
    end
  end
end