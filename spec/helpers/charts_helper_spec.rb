require "rails_helper"

RSpec.describe ChartsHelper, type: :helper do
  include described_class

  describe "#chart_options" do
    it "uses second unit for short timespans" do
      min = Time.zone.parse("2025-01-01 10:00:00")
      max = min + 20.minutes
      options = chart_options(min, max)
      expect(options.dig(:library, :scales, :x, :time, :unit)).to eq("second")
    end

    it "uses minute unit for medium timespans" do
      min = Time.zone.parse("2025-01-01 10:00:00")
      max = min + 2.hours
      options = chart_options(min, max)
      expect(options.dig(:library, :scales, :x, :time, :unit)).to eq("minute")
    end

    it "uses hour unit for multi-hour timespans" do
      min = Time.zone.parse("2025-01-01 10:00:00")
      max = min + 1.day
      options = chart_options(min, max)
      expect(options.dig(:library, :scales, :x, :time, :unit)).to eq("hour")
    end

    it "uses day unit for multi-day timespans" do
      min = Time.zone.parse("2025-01-01 10:00:00")
      max = min + 7.days
      options = chart_options(min, max)
      expect(options.dig(:library, :scales, :x, :time, :unit)).to eq("day")
    end

    it "uses month unit for long timespans" do
      min = Time.zone.parse("2025-01-01 10:00:00")
      max = min + 11.months
      options = chart_options(min, max)
      expect(options.dig(:library, :scales, :x, :time, :unit)).to eq("month")
    end
  end
end
