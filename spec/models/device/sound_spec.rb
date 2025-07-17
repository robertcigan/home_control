require "rails_helper"

RSpec.describe Device::Sound, type: :model do
  let!(:sound) { create(:sound) }

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
    it "calls play_sound with provided arguments" do
      expect(sound).to receive(:play_sound).with(50, "0", "1.mp3")
      sound.activate(50, "0", "1.mp3")
    end

    it "updates last_change timestamp" do
      expect { sound.activate(50, "0", "1.mp3") }.to change { sound.reload.last_change }
    end
  end

  describe "#status" do
    it "returns formatted last_change time when present" do
      sound.last_change = Time.parse("2023-01-01 12:00:00")
      expect(sound.status).to eq("2023-01-01 12:00:00")
    end

    it "returns nil when last_change is nil" do
      sound.last_change = nil
      expect(sound.status).to be_nil
    end
  end

  describe "#indication" do
    it "returns last_change_text" do
      sound.last_change = Time.current
      expect(sound.indication).to eq(sound.last_change_text)
    end
  end

  describe "#value" do
    it "returns last_change" do
      time = Time.current
      sound.last_change = time
      expect(sound.value).to eq(time)
    end
  end

  describe "#value=" do
    it "sets last_change" do
      time = Time.current
      sound.value = time
      expect(sound.last_change).to eq(time)
    end
  end

  describe "#setup_pin" do
    it "sends add command to board with correct parameters" do
      expect(sound).to receive(:send_to_board).with(
        add: { id: sound.id, type: "player" }
      )
      sound.setup_pin
    end
  end

  describe "#writable?" do
    it "returns false (inherited from Device)" do
      expect(sound.writable?).to be false
    end
  end

  describe "#readable?" do
    it "returns false (inherited from Device)" do
      expect(sound.readable?).to be false
    end
  end

  describe "#poll?" do
    it "returns false (inherited from Device)" do
      expect(sound.poll?).to be false
    end
  end

  describe "#toggle?" do
    it "returns false (inherited from Device)" do
      expect(sound.toggle?).to be false
    end
  end

  describe "#to_s" do
    it "returns the device name" do
      sound.name = "Test Sound"
      expect(sound.to_s).to eq("Test Sound")
    end

    it "returns 'UNKNOWN' when name is not present" do
      sound.name = nil
      expect(sound.to_s).to eq("UNKNOWN")
    end
  end

  describe "#json_data" do
    it "includes status, updated, value, and indication" do
      sound.last_change = Time.current
      json_data = sound.json_data

      expect(json_data).to include(:status, :updated, :value, :indication)
    end

    it "includes id from websocket_push_change concern" do
      json_data = sound.json_data
      expect(json_data).to include(:id)
    end
  end

  describe "#volume" do
    it "sends volume command to board" do
      expect(sound).to receive(:send_to_board).with(
        write: { id: sound.id, volume: 75 }
      )
      sound.send(:volume, 75)
    end
  end

  describe "#play_sound" do
    it "sends volume and file commands to board" do
      expect(sound).to receive(:send_to_board).with(write: { id: sound.id, volume: 50 })
      expect(sound).to receive(:send_to_board).with(
        write: { id: sound.id, directory: "/sounds", file: "test.mp3" }
      )
      sound.send(:play_sound, 50, "/sounds", "test.mp3")
    end
  end

  describe "#log_device_log" do
    it "creates device log when last_change changes" do
      expect {
        sound.update!(last_change: Time.current)
      }.to change { sound.device_logs.count }.by(1)
    end

    it "does not create log when last_change does not change" do
      expect {
        sound.update!(name: "New Name")
      }.not_to change { sound.device_logs.count }
    end

    it "creates device log when log_enabled is true" do
      sound.update!(log_enabled: true)
      expect {
        sound.update!(last_change: Time.current)
      }.to change { sound.device_logs.count }.by(1)
    end

    it "does not create device log when log_enabled is false" do
      sound.update!(log_enabled: false)
      expect {
        sound.update!(last_change: Time.current)
      }.not_to change { sound.device_logs.count }
    end
  end

  describe "callbacks" do
    describe "after_create" do
      it "calls reset_pins after creation" do
        new_sound = build(:sound)
        expect(new_sound).to receive(:reset_pins)
        new_sound.save!
      end
    end

    describe "after_destroy" do
      it "calls reset_pins after destruction" do
        expect(sound).to receive(:reset_pins)
        sound.destroy
      end
    end

    describe "after_save" do
      it "calls detect_log_enabled_change after save" do
        expect(sound).to receive(:detect_log_enabled_change)
        sound.update!(name: "New Name")
      end
    end

    describe "after_update" do
      it "calls detect_hw_change after update" do
        expect(sound).to receive(:detect_hw_change)
        sound.update!(pin: 5)
      end
    end
  end

  describe "inherited methods" do
    describe "#last_change_text" do
      it "returns formatted time when last_change is present" do
        time = Time.parse("2023-01-01 12:00:00")
        sound.last_change = time
        expect(sound.last_change_text).to eq(I18n.l(time, format: :custom))
      end

      it "returns nil when last_change is nil" do
        sound.last_change = nil
        expect(sound.last_change_text).to be_nil
      end
    end

    describe "#send_to_board" do
      it "delegates to board send_to_board method" do
        data = { test: "data" }
        expect(sound.board).to receive(:send_to_board).with(data)
        sound.send_to_board(data)
      end
    end

    describe "#clear_logs" do
      it "deletes old logs based on days_to_preserve_logs" do
        sound.update!(days_to_preserve_logs: 7)
        old_log = create(:device_log, device: sound, created_at: 10.days.ago)
        new_log = create(:device_log, device: sound, created_at: 1.day.ago)

        expect { sound.clear_logs }.to change { sound.device_logs.count }.by(-1)
        expect(sound.device_logs).not_to include(old_log)
        expect(sound.device_logs).to include(new_log)
      end
    end
  end

  describe "integration tests" do
    let(:board) { sound.board }

    describe "full sound lifecycle" do
      it "can be created, configured, and activated" do
        # Test creation
        expect(sound).to be_valid
        expect(sound.device_type).to eq("Device::Sound")

        # Test setup
        expect(sound).to receive(:send_to_board).with(
          add: { id: sound.id, type: "player" }
        )
        sound.setup_pin

        # Test activation
        expect(sound).to receive(:send_to_board).with(
          write: { id: sound.id, volume: 75 }
        )
        expect(sound).to receive(:send_to_board).with(
          write: { id: sound.id, directory: "/sounds", file: "test.mp3" }
        )
        sound.activate(75, "/sounds", "test.mp3")
        expect(sound.last_change).to be_present

        # Test status and indication
        expect(sound.status).to be_present
        expect(sound.indication).to be_present
      end
    end

    describe "with board interaction" do
      it "delegates board communication correctly" do
        expect(board).to receive(:send_to_board).with({ add: { id: sound.id, type: "player" }})
        sound.setup_pin

        expect(board).to receive(:send_to_board).with({ write: { id: sound.id, volume: 50 }})
        expect(board).to receive(:send_to_board).with({ write: { id: sound.id, directory: "/sounds", file: "test.mp3" }} )
        sound.activate(50, "/sounds", "test.mp3")
      end
    end

    describe "volume control" do
      it "can control volume independently" do
        expect(board).to receive(:send_to_board).with({ write: { id: sound.id, volume: 25 }})
        sound.send(:volume, 25)
      end
    end

    describe "sound playback" do
      it "handles different volume levels" do
        expect(board).to receive(:send_to_board).with({ write: { id: sound.id, volume: 0 }})
        expect(board).to receive(:send_to_board).with({ write: { id: sound.id, directory: "/sounds", file: "quiet.mp3" }})
        sound.send(:play_sound, 0, "/sounds", "quiet.mp3")

        expect(board).to receive(:send_to_board).with({ write: { id: sound.id, volume: 100 }})
        expect(board).to receive(:send_to_board).with({ write: { id: sound.id, directory: "/sounds", file: "loud.mp3" }})
        sound.send(:play_sound, 100, "/sounds", "loud.mp3")
      end

      it "handles different directories and files" do
        expect(board).to receive(:send_to_board).with({ write: { id: sound.id, volume: 50 }})
        expect(board).to receive(:send_to_board).with({ write: { id: sound.id, directory: "/alerts", file: "warning.mp3" }})
        sound.send(:play_sound, 50, "/alerts", "warning.mp3")
      end
    end
  end
end