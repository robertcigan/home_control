require "rails_helper"

RSpec.describe ChartsHelper, type: :helper do
  include described_class

  describe "#chart_data_attributes" do
    let(:min) { Time.zone.parse("2025-01-01 00:00:00") }
    let(:max) { Time.zone.parse("2025-01-01 23:59:59") }

    it "builds stimulus data attributes for the chart controller" do
      attrs = chart_data_attributes("/devices/1/device_logs/chart.json", min, max,
        type: "step-area",
        title_y: "On/Off",
        timespan: "day",
        multi: true)

      expect(attrs[:controller]).to eq("chart")
      expect(attrs[:chart_url_value]).to eq("/devices/1/device_logs/chart.json")
      expect(attrs[:chart_type_value]).to eq("step-area")
      expect(attrs[:chart_y_title_value]).to eq("On/Off")
      expect(attrs[:chart_timespan_value]).to eq("day")
      expect(attrs[:chart_multi_value]).to eq(true)
      expect(attrs[:chart_min_value]).to eq(min.iso8601)
      expect(attrs[:chart_max_value]).to eq(max.iso8601)
      expect(attrs[:chart_now_value]).to be_present
    end

    it "defaults type, title, timespan and multi" do
      attrs = chart_data_attributes("/chart.json", min, max)
      expect(attrs[:chart_type_value]).to eq("line")
      expect(attrs[:chart_y_title_value]).to eq("")
      expect(attrs[:chart_timespan_value]).to eq("day")
      expect(attrs[:chart_multi_value]).to eq(false)
    end
  end

  describe "#chart_window_label" do
    let(:min) { Time.zone.parse("2025-01-01 12:00:00") }

    it "formats day windows" do
      expect(chart_window_label(min, "day")).to eq(I18n.l(min, format: :date))
    end

    it "formats hour windows" do
      expect(chart_window_label(min, "hour")).to eq(I18n.l(min, format: :day_and_hour))
    end
  end

  describe "#device_chart_type" do
    it "returns step-area for boolean devices" do
      device = build(:relay, value_boolean: true)
      expect(device_chart_type(device)).to eq("step-area")
    end

    it "returns line for decimal and integer devices" do
      expect(device_chart_type(build(:ds18b20))).to eq("line")
      expect(device_chart_type(build(:virtual_integer))).to eq("line")
    end

    it "returns points for string devices" do
      expect(device_chart_type(build(:virtual_string))).to eq("points")
    end
  end

  describe "#widget_chart_type" do
    let(:device) { build(:ds18b20) }

    it "uses device auto type when chart_type is auto" do
      widget = build(:widget, :type_chart, device: device, chart_type: "auto")
      expect(widget_chart_type(widget)).to eq("line")
    end

    it "maps step_area to the JS step-area type" do
      widget = build(:widget, :type_chart, device: device, chart_type: "step_area")
      expect(widget_chart_type(widget)).to eq("step-area")
    end

    it "passes through explicit line, area and points" do
      expect(widget_chart_type(build(:widget, :type_chart, device: device, chart_type: "area"))).to eq("area")
      expect(widget_chart_type(build(:widget, :type_chart, device: device, chart_type: "points"))).to eq("points")
    end
  end

  describe "#device_chart_y_title" do
    it "returns the device unit when present" do
      device = build(:ds18b20, unit: "°C")
      expect(device_chart_y_title(device)).to eq("°C")
    end

    it "returns blank when no unit is set" do
      expect(device_chart_y_title(build(:ds18b20, unit: nil))).to eq("")
      expect(device_chart_y_title(build(:relay))).to eq("")
    end
  end
end
