require "rails_helper"

RSpec.describe Widget, type: :model do
  let(:widget) { create(:widget, :type_button) }

  describe "validations" do
    describe "chart widget" do
      let(:log_device) { create(:ds18b20, log_enabled: true) }
      let(:no_log_device) { create(:ds18b20, log_enabled: false, pin: 3) }

      it "is valid with a log-enabled device" do
        widget = build(:widget, :type_chart, device: log_device)
        expect(widget).to be_valid
      end

      it "is invalid without a device" do
        widget = build(:widget, :type_chart, device: nil)
        expect(widget).not_to be_valid
        expect(widget.errors[:device]).to be_present
      end

      it "is invalid when device has logging disabled" do
        widget = build(:widget, :type_chart, device: no_log_device)
        expect(widget).not_to be_valid
        expect(widget.errors[:device]).to include("must have logging enabled to draw a chart")
      end

      it "rejects nil, zero, and negative time_window_hours" do
        [nil, 0, -5].each do |hours|
          widget = build(:widget, :type_chart, device: log_device, time_window_hours: hours)
          expect(widget).not_to be_valid
          expect(widget.errors[:time_window_hours]).to be_present
        end
      end

      it "allows decimal time_window_hours" do
        widget = build(:widget, :type_chart, device: log_device, time_window_hours: 0.1)
        expect(widget).to be_valid
      end

      it "allows nil time_window_hours for non-chart widgets" do
        widget = build(:widget, :type_button, time_window_hours: nil)
        widget.valid?
        expect(widget.errors[:time_window_hours]).to be_blank
      end

      it "defaults time_window_hours to 24" do
        expect(Widget.new.time_window_hours).to eq(24)
      end

      it "defaults chart_type to auto" do
        expect(Widget.new.chart_type).to eq("auto")
      end

      it "allows selecting a concrete chart_type" do
        widget = build(:widget, :type_chart, device: log_device, chart_type: "area")
        expect(widget).to be_valid
      end

      it "rejects an unknown chart_type" do
        widget = build(:widget, :type_chart, device: log_device, chart_type: "bar")
        expect(widget).not_to be_valid
        expect(widget.errors[:chart_type]).to be_present
      end
    end
  end

  describe "associations" do
    it { should belong_to(:panel) }
    it { should belong_to(:device).optional }
    it { should belong_to(:program).optional }
  end

  describe "#to_s" do
    it "returns the widget name" do
      expect(widget.to_s).to eq(widget.name)
    end
  end
end
