require "rails_helper"

RSpec.describe Device::Button, type: :model do
  let(:button) { create(:button) }

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
      expect { button.set(true) }.to change { button.reload.last_change }.from(nil)
    end
  end

  describe "#status" do
    it "returns the current value" do
      button.update!(last_change: Time.parse("2025-01-01 12:00:00"))
      expect(button.status).to eq("2025-01-01 12:00:00")
    end
  end

  describe "#indication" do
    it "returns value when value is present" do
      button.last_change = Time.parse("2025-01-01 12:00:00")
      expect(button.indication).to eq("1.1.2025 12:00:00")
    end
  end

  describe "#value" do
    it "returns the last_change value" do
      button.update!(last_change: Time.parse("2025-01-01 12:00:00"))
      expect(button.value).to eq(Time.parse("2025-01-01 12:00:00"))
    end
  end

  describe "#value=" do
    it "sets the boolean value" do
      button.value = Time.parse("2025-01-01 12:00:00")
      expect(button.last_change).to eq(Time.parse("2025-01-01 12:00:00"))
    end
  end

  describe "#setup_pin" do
    it "sends add command to board with correct parameters" do
      expect(button).to receive(:send_to_board).with(
        add: { id: button.id, type: "button", pin: button.pin, poll: button.poll || 100, inverted: button.inverted }
      )
      button.setup_pin
    end
  end

  describe "#readable?" do
    it "returns true" do
      expect(button.readable?).to be false
    end
  end

  describe "#poll?" do
    it "returns true" do
      expect(button.poll?).to be true
    end
  end

  describe "#writable?" do
    it "returns false (inherited from Device)" do
      expect(button.writable?).to be false
    end
  end

  describe "#toggle?" do
    it "returns false (inherited from Device)" do
      expect(button.toggle?).to be false
    end
  end

  describe "#to_s" do
    it "returns the device name" do
      button.name = "Test Button"
      expect(button.to_s).to eq("Test Button")
    end
  end

  describe "#detect_change" do
    it "calls trigger_programs when last_change changes" do
      button.update!(last_change: Time.parse("2025-01-01 12:00:00"))
      expect(button).to receive(:trigger_programs)
      button.update!(last_change: Time.parse("2025-01-01 12:00:01"))
    end
  end

  describe "#log_device_log" do
    let!(:time) { Time.parse("2025-01-01 12:00:00") }

    it "creates device log when last_change changes" do
      button.update!(last_change: time - 5.seconds)
      Timecop.freeze(time) do
        expect {
          button.set(Time.parse("2025-01-01 12:00:01"))
        }.to change { button.device_logs.count }.by(1)

        log = button.device_logs.last
        expect(log.created_at).to eq(time)
      end
    end

    it "does not create log when last_change does not change" do
      expect {
        button.update!(name: "New Name")
      }.not_to change { button.device_logs.count }
    end
  end

  describe "callbacks" do
    describe "after_commit :detect_change" do
      it "triggers programs when value_boolean changes" do
        button.update!(value_boolean: false)
        expect(button).to receive(:trigger_programs)
        button.update!(last_change: Time.parse("2025-01-01 12:00:01"))
      end

      it "does not trigger programs when other attributes change" do
        expect(button).not_to receive(:trigger_programs)
        button.update!(name: "New Name")
      end
    end
  end
end