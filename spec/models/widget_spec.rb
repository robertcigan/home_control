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

  describe "position of a new widget" do
    let(:panel) { create(:panel, column: 3, row: 2) }

    def unplaced_widget
      create(:widget, :type_button, panel: panel, x: nil, y: nil, w: nil, h: nil)
    end

    it "is put into the first free cell of the panel" do
      create(:widget, :type_button, panel: panel, x: 0, y: 0, w: 2, h: 1)
      create(:widget, :type_button, panel: panel, x: 2, y: 0, w: 1, h: 2)

      expect(unplaced_widget).to have_attributes(x: 0, y: 1, w: 1, h: 1)
    end

    it "puts several new widgets into different cells" do
      first = unplaced_widget
      second = unplaced_widget

      expect([first.x, first.y]).to eq([0, 0])
      expect([second.x, second.y]).to eq([1, 0])
    end

    it "places widgets created together through the panel form" do
      panel.update!(widgets_attributes: [
        { widget_type: Widget::WidgetType::TEXT_VALUE, device_id: create(:ds18b20).id },
        { widget_type: Widget::WidgetType::TEXT_VALUE, device_id: create(:ds18b20, pin: 3).id }
      ])

      expect(panel.widgets.in_grid_order.pluck(:x, :y, :w, :h)).to eq([[0, 0, 1, 1], [1, 0, 1, 1]])
    end

    it "stays empty when the panel is full" do
      create(:widget, :type_button, panel: panel, x: 0, y: 0, w: 3, h: 2)

      expect(unplaced_widget).to have_attributes(x: nil, y: nil, w: nil, h: nil)
    end

    it "keeps an explicitly given position" do
      widget = create(:widget, :type_button, panel: panel, x: 2, y: 1, w: 1, h: 1)

      expect(widget).to have_attributes(x: 2, y: 1)
    end
  end

  describe "#to_s" do
    it "returns the widget name" do
      expect(widget.to_s).to eq(widget.name)
    end
  end
end
