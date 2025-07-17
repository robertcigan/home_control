require "rails_helper"

RSpec.describe Device::Curtain, type: :model do
  let(:curtain) { create(:curtain) }

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

  describe "#activate" do
    it "calls activate_curtain with provided arguments" do
      expect(curtain).to receive(:activate_curtain).with("open", 5000)
      curtain.activate("open", 5000)
    end

    it "updates last_change timestamp" do
      expect { curtain.activate("open", 5000) }.to change { curtain.reload.last_change }
    end
  end

  describe "#status" do
    it "returns formatted last_change time when present" do
      curtain.last_change = Time.parse("2023-01-01 12:00:00")
      expect(curtain.status).to eq("2023-01-01 12:00:00")
    end

    it "returns nil when last_change is nil" do
      curtain.last_change = nil
      expect(curtain.status).to be_nil
    end
  end

  describe "#indication" do
    it "returns last_change_text" do
      curtain.last_change = Time.current
      expect(curtain.indication).to eq(curtain.last_change_text)
    end
  end

  describe "#value" do
    it "returns last_change" do
      time = Time.current
      curtain.last_change = time
      expect(curtain.value).to eq(time)
    end
  end

  describe "#value=" do
    it "sets last_change" do
      time = Time.current
      curtain.value = time
      expect(curtain.last_change).to eq(time)
    end
  end

  describe "#setup_pin" do
    it "sends add command to board with correct parameters" do
      expect(curtain).to receive(:send_to_board).with({ add: { id: curtain.id, type: "curtain", open_pin: curtain.pin, close_pin: curtain.pin + 1, inverted: curtain.inverted }})
      curtain.setup_pin
    end
  end

  describe "#writable?" do
    it "returns false (inherited from Device)" do
      expect(curtain.writable?).to be false
    end
  end

  describe "#readable?" do
    it "returns false (inherited from Device)" do
      expect(curtain.readable?).to be false
    end
  end

  describe "#poll?" do
    it "returns false (inherited from Device)" do
      expect(curtain.poll?).to be false
    end
  end

  describe "#toggle?" do
    it "returns false (inherited from Device)" do
      expect(curtain.toggle?).to be false
    end
  end

  describe "#to_s" do
    it "returns the device name" do
      curtain.name = "Test Curtain"
      expect(curtain.to_s).to eq("Test Curtain")
    end
  end

  describe "#json_data" do
    it "includes status, updated, value, and indication" do
      curtain.last_change = Time.current
      json_data = curtain.json_data

      expect(json_data).to include(:status, :updated, :value, :indication)
    end
  end

  describe "#activate_curtain" do
    it "sends open command to board when direction is open" do
      expect(curtain).to receive(:send_to_board).with({ write: { id: curtain.id, action: "open", value: 5000 }})
      curtain.send(:activate_curtain, "open", 5000)
    end

    it "sends close command to board when direction is close" do
      expect(curtain).to receive(:send_to_board).with({ write: { id: curtain.id, action: "close", value: 3000 }})
      curtain.send(:activate_curtain, "close", 3000)
    end

    it "does not send command to board when direction is neither open nor close" do
      expect(curtain).not_to receive(:send_to_board)
      curtain.send(:activate_curtain, "invalid", 1000)
    end
  end

  describe "#log_device_log" do
    it "creates device log when last_change changes" do
      time = Time.current
      Timecop.freeze(time) do
        expect {curtain.update!(last_change: time)}.to change { curtain.device_logs.count }.by(1)
        log = curtain.device_logs.last
        expect(log.created_at).to eq(time)
      end
    end

    it "does not create log when last_change does not change" do
      time = Time.current
      Timecop.freeze(time) do
        expect { curtain.update!(name: "New Name") }.not_to change { curtain.device_logs.count }
      end
    end
  end
end