require "rails_helper"

RSpec.describe LogCompression, type: :model do
  describe "#compressable?" do
    it "returns true for integer and decimal devices" do
      expect(build(:virtual_integer)).to be_compressable
      expect(build(:virtual_decimal)).to be_compressable
    end

    it "returns false for boolean and string devices" do
      expect(build(:virtual_boolean)).not_to be_compressable
      expect(build(:virtual_string)).not_to be_compressable
    end
  end

  describe "#run_compression" do
    let(:base_time) { Time.zone.parse("2025-03-01 10:00:00") }

    def compression_device(trait, **attrs)
      create(:virtual_integer, trait, { log_enabled: false }.merge(attrs))
    end

    it "derives start time from first log when compression_last_run_at is nil" do
      device = compression_device(:compression_average_min1, compression_last_run_at: nil)
      create(:device_log, :with_integer_value, device: device, value_integer: 10, created_at: base_time + 10.seconds)
      create(:device_log, :with_integer_value, device: device, value_integer: 30, created_at: base_time + 40.seconds)

      Timecop.freeze(base_time + 3.minutes) do
        result = device.run_compression(true)
        expect(result).to be_a(DeviceLog)
        expect(device.reload.compression_last_run_at).to eq(base_time)
      end
    end

    it "derives subsequent start time from compression_last_run_at" do
      device = compression_device(:compression_average_min1, compression_last_run_at: base_time)
      next_window = base_time + 1.minute
      create(:device_log, :with_integer_value, device: device, value_integer: 10,
        created_at: next_window + 10.seconds)
      create(:device_log, :with_integer_value, device: device, value_integer: 30,
        created_at: next_window + 40.seconds)

      Timecop.freeze(base_time + 4.minutes) do
        device.run_compression(true)
        expect(device.reload.compression_last_run_at).to eq(next_window)
      end
    end

    it "does not compress when backlog window has not elapsed" do
      device = compression_device(:compression_average_min1, compression_last_run_at: nil)
      create(:device_log, :with_integer_value, device: device, value_integer: 10, created_at: base_time)

      Timecop.freeze(base_time + 30.seconds) do
        expect(device.run_compression(true)).to be_nil
      end
    end

    it "advances timestamp only for single-row window with replace_logs" do
      device = compression_device(:compression_average_min1, compression_last_run_at: nil)
      create(:device_log, :with_integer_value, device: device, value_integer: 10, created_at: base_time + 10.seconds)

      Timecop.freeze(base_time + 3.minutes) do
        expect(device.device_logs.count).to eq(1)
        device.run_compression(true)
        expect(device.device_logs.count).to eq(1)
        expect(device.reload.compression_last_run_at).to eq(base_time)
      end
    end
  end

  describe "#compress_logs" do
    let(:window_start) { Time.zone.parse("2025-03-01 10:00:00") }

    def compression_device(trait, **attrs)
      create(:virtual_integer, trait, { log_enabled: false }.merge(attrs))
    end

    it "compresses with average type at window start" do
      device = compression_device(:compression_average_min1)
      create(:device_log, :with_integer_value, device: device, value_integer: 10,
        created_at: window_start + 10.seconds)
      create(:device_log, :with_integer_value, device: device, value_integer: 30,
        created_at: window_start + 40.seconds)

      result = device.compress_logs(window_start, true)
      expect(result.value_integer).to eq(20)
      expect(result.created_at).to eq(window_start)
      expect(device.device_logs.count).to eq(1)
    end

    it "compresses with weighted average including previous window boundary" do
      device = compression_device(:compression_w_average_min5)
      create(:device_log, :with_integer_value, device: device, value_integer: 100,
        created_at: window_start - 2.minutes)
      create(:device_log, :with_integer_value, device: device, value_integer: 10,
        created_at: window_start + 1.minute)
      create(:device_log, :with_integer_value, device: device, value_integer: 30,
        created_at: window_start + 3.minutes)

      result = device.compress_logs(window_start, false)
      expect(result).to be_a(DeviceLog)
      expect(result.value_integer).to be > 0
    end

    it "compresses with end_value at window end" do
      device = compression_device(:compression_end_value_hour)
      create(:device_log, :with_integer_value, device: device, value_integer: 10,
        created_at: window_start + 10.minutes)
      create(:device_log, :with_integer_value, device: device, value_integer: 50,
        created_at: window_start + 40.minutes)

      result = device.compress_logs(window_start, false)
      expect(result.value_integer).to eq(50)
      expect(result.created_at).to eq(window_start.end_of_hour)
    end

    it "compresses with max_value at window end" do
      device = compression_device(:compression_max_value_day)
      create(:device_log, :with_integer_value, device: device, value_integer: 10,
        created_at: window_start + 2.hours)
      create(:device_log, :with_integer_value, device: device, value_integer: 80,
        created_at: window_start + 5.hours)

      result = device.compress_logs(window_start, false)
      expect(result.value_integer).to eq(80)
      expect(result.created_at).to eq(window_start.end_of_day)
    end

    it "replaces source logs and advances compression_last_run_at" do
      device = compression_device(:compression_average_min1, compression_last_run_at: nil)
      create(:device_log, :with_integer_value, device: device, value_integer: 10,
        created_at: window_start + 10.seconds)
      create(:device_log, :with_integer_value, device: device, value_integer: 30,
        created_at: window_start + 40.seconds)

      device.compress_logs(window_start, true)
      expect(device.device_logs.count).to eq(1)
      expect(device.reload.compression_last_run_at).to eq(window_start)
    end
  end
end
