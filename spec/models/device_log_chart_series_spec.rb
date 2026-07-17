require "rails_helper"

RSpec.describe DeviceLog, type: :model do
  describe ".chart_series" do
    let(:frozen_time) { Time.zone.parse("2025-06-15 12:00:00") }
    let(:min) { frozen_time.beginning_of_day }
    let(:max) { frozen_time.end_of_day }

    it "returns numeric points without aggregation under the cap" do
      device = create(:virtual_integer, name: "Series Device", value_integer: 1)
      create(:device_log, :with_integer_value, device: device, value_integer: 10, created_at: min + 1.hour)
      create(:device_log, :with_integer_value, device: device, value_integer: 20, created_at: min + 2.hours)

      series = described_class.chart_series(device, min, max, cap: 100)
      expect(series.map(&:last)).to eq([10, 20])
    end

    it "aggregates numeric values with date_bin averages when over the cap" do
      device = create(:virtual_integer, name: "Agg Device", value_integer: 1)
      cap = 5

      20.times do |i|
        create(:device_log, :with_integer_value, device: device, value_integer: (i + 1) * 10,
          created_at: min + (i * 10).minutes)
      end

      series = described_class.chart_series(device, min, max, cap: cap)
      expect(series.length).to be <= cap
      expect(series.map(&:last)).to all(be_a(Numeric))
      expect(series.map(&:last).sum).to be > 0
    end

    it "keeps boolean values as 0/1 without averaging" do
      board = create(:board, name: "Bool Series Board", ip: "192.168.9.9")
      device = create(:relay, name: "Bool Series", board: board, pin: 1, log_enabled: true)

      create(:device_log, :with_boolean_value, device: device, value_boolean: false, created_at: min + 1.hour)
      create(:device_log, :with_boolean_value, device: device, value_boolean: true, created_at: min + 2.hours)

      series = described_class.chart_series(device, min, max, cap: 10)
      expect(series.map(&:last)).to eq([0, 1])
    end

    it "returns all boolean points without sampling even above the cap" do
      board = create(:board, name: "Sample Board", ip: "192.168.9.10")
      device = create(:relay, name: "Sample Bool", board: board, pin: 2, log_enabled: true)
      cap = 4
      total = (4 * cap) + 5

      total.times do |i|
        create(:device_log, :with_boolean_value, device: device, value_boolean: i.even?,
          created_at: min + i.minutes)
      end

      series = described_class.chart_series(device, min, max, cap: cap)
      expect(series.length).to eq(total)
      expect(series.map(&:last)).to eq(total.times.map { |i| i.even? ? 1 : 0 })
    end
  end
end
