require "rails_helper"

RSpec.describe Device::VirtualString, type: :model do
  let(:virtual_string) { create(:virtual_string) }

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
      virtual_string.update!(value_string: "old")
      expect { virtual_string.set("new") }.to change { virtual_string.reload.value_string }.from("old").to("new")
    end
  end

  describe "#status" do
    it "returns the current value" do
      virtual_string.update!(value_string: "old")
      expect(virtual_string.status).to eq("old")
      virtual_string.value_string = "new"
      expect(virtual_string.status).to eq("new")
    end
  end

  describe "#value" do
    it "returns the string value" do
      virtual_string.update!(value_string: "old")
      expect(virtual_string.value).to eq("old")
      virtual_string.value_string = "new"
      expect(virtual_string.value).to eq("new")
    end
  end

  describe "#value=" do
    it "sets the string value" do
      virtual_string.value = "new"
      expect(virtual_string.value_string).to eq("new")
    end
  end

  describe "#value_attribute" do
    it "returns :value_string" do
      expect(virtual_string.value_attribute).to eq(:value_string)
    end
  end

  describe "#toggle?" do
    it "returns false (inherited from Device)" do
      expect(virtual_string.toggle?).to be false
    end
  end

  describe "#readable?" do
    it "returns false (inherited from Device)" do
      expect(virtual_string.readable?).to be false
    end
  end

  describe "#poll?" do
    it "returns false (inherited from Device)" do
      expect(virtual_string.poll?).to be false
    end
  end

  describe "#to_s" do
    it "returns the device name" do
      virtual_string.name = "Test Virtual String"
      expect(virtual_string.to_s).to eq("Test Virtual String")
    end
  end

  describe "#json_data" do
    it "includes status, updated, value, and indication" do
      virtual_string.value_string = "test"
      virtual_string.last_change = Time.current
      json_data = virtual_string.json_data

      expect(json_data).to include(:status, :updated, :value, :indication)
    end
  end

  describe "#detect_change" do
    it "calls trigger_programs when value_string changes" do
      virtual_string = create(:virtual_string, value_string: "old")
      expect(virtual_string).to receive(:trigger_programs)
      virtual_string.update!(value_string: "new")
    end
  end

  describe "#reset_pins" do
    it "does nothing (overridden from Device)" do
      expect { virtual_string.send(:reset_pins) }.not_to raise_error
    end
  end

  describe "#log_device_log" do
    it "creates device log when value_string changes" do
      virtual_string.update!(value_string: "old")
      expect { virtual_string.update!(value_string: "new") }.to change { virtual_string.device_logs.count }.by(1)
      log = virtual_string.device_logs.last
      expect(log.value_string).to eq("new")
    end

    it "updates last_change when value_string changes" do
      virtual_string.update!(value_string: "old")
      expect { virtual_string.update!(value_string: "new") }.to change { virtual_string.reload.last_change }
    end

    it "does not create log when value_string does not change" do
      expect { virtual_string.update!(name: "New Name") }.not_to change { virtual_string.device_logs.count }
    end
  end

  describe "callbacks" do
    describe "after_commit :detect_change" do
      it "triggers programs when value_string changes" do
        virtual_string = create(:virtual_string, value_string: "old")
        expect(virtual_string).to receive(:trigger_programs)
        virtual_string.update!(value_string: "new")
      end

      it "does not trigger programs when other attributes change" do
        expect(virtual_string).not_to receive(:trigger_programs)
        virtual_string.update!(name: "New Name")
      end
    end
  end
end