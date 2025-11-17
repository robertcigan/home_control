require "rails_helper"

RSpec.describe Device::Pwm, type: :model do
  let(:pwm) { create(:pwm) }

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
      expect { pwm.set(50) }.to change { pwm.reload.value_integer }.from(0).to(50)
    end
  end

  describe "#status" do
    it "returns the current value" do
      pwm.update!(value_integer: 0)
      expect(pwm.status).to eq(0)
      pwm.value_integer = 50
      expect(pwm.status).to eq(50)
    end
  end

  describe "#indication" do
    it "includes unit in indication when unit is present" do
      pwm.update!(unit: "%", value_integer: 50)
      expect(pwm.indication).to eq("50%")
    end
  end

  describe "#value" do
    it "returns the integer value" do
      pwm.update!(value_integer: 0)
      expect(pwm.value).to eq(0)
      pwm.value_integer = 50
      expect(pwm.value).to eq(50)
    end
  end

  describe "#value=" do
    it "sets the integer value" do
      pwm.value = 50
      expect(pwm.value_integer).to eq(50)
    end
  end

  describe "#setup_pin" do
    it "sends add command to board with correct parameters" do
      expect(pwm).to receive(:send_to_board).with({add: { id: pwm.id, type: "pwm", pin: pwm.pin, default_value: 0 }})
      expect(pwm).to receive(:send_to_board).with({write: { id: pwm.id, type: "pwm", value: 0 }})
      pwm.setup_pin
    end
  end

  describe "#writable?" do
    it "returns true" do
      expect(pwm.writable?).to be true
    end
  end

  describe "#set_value_to_board" do
    it "sends write command to board with correct parameters" do
      expect(pwm).to receive(:send_to_board).with({write: { id: pwm.id, type: "pwm", value: pwm.value }})
      pwm.set_value_to_board
    end
  end

  describe "#value_attribute" do
    it "returns :value_integer" do
      expect(pwm.value_attribute).to eq(:value_integer)
    end
  end

  describe "#readable?" do
    it "returns false (inherited from Device)" do
      expect(pwm.readable?).to be false
    end
  end

  describe "#poll?" do
    it "returns false (inherited from Device)" do
      expect(pwm.poll?).to be false
    end
  end

  describe "#toggle?" do
    it "returns false (inherited from Device)" do
      expect(pwm.toggle?).to be false
    end
  end

  describe "#to_s" do
    it "returns the device name" do
      pwm.name = "Test PWM"
      expect(pwm.to_s).to eq("Test PWM")
    end
  end

  describe "#detect_change" do
    it "calls set_value_to_board when value_integer changes" do
      expect(pwm).to receive(:set_value_to_board)
      pwm.update!(value_integer: 50)
    end

    it "calls trigger_programs when value_integer changes" do
      expect(pwm).to receive(:trigger_programs)
      pwm.update!(value_integer: 50)
    end
  end

  describe "#log_device_log" do
    it "creates device log when value_integer changes" do
      pwm.update!(value_integer: 0)
      time = Time.current
      Timecop.freeze(time) do
        expect { pwm.update!(value_integer: 50) }.to change { pwm.device_logs.count }.by(1)
        log = pwm.device_logs.last
        expect(log.value_integer).to eq(50)
      end
    end

    it "updates last_change when value_integer changes" do
      pwm.update!(value_integer: 0)
      time = Time.current
      Timecop.freeze(time) do
        expect { pwm.update!(value_integer: 50) }.to change { pwm.reload.last_change }
      end
    end

    it "does not create log when value_integer does not change" do
      time = Time.current
      Timecop.freeze(time) do
        expect { pwm.update!(name: "New Name") }.not_to change { pwm.device_logs.count }
      end
    end
  end

  describe "callbacks" do
    describe "after_commit :detect_change" do
      it "calls set_value_to_board when value_integer changes" do
        pwm.update!(value_integer: 0)
        expect(pwm).to receive(:set_value_to_board)
        pwm.update!(value_integer: 50)
      end

      it "triggers programs when value_integer changes" do
        pwm.update!(value_integer: 0)
        expect(pwm).to receive(:trigger_programs)
        pwm.update!(value_integer: 50)
      end

      it "does not call set_value_to_board when other attributes change" do
        expect(pwm).not_to receive(:set_value_to_board)
        pwm.update!(name: "New Name")
      end
    end
  end
end
