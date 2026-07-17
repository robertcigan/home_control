require "rails_helper"

RSpec.describe "Widget chart JSON", type: :request do
  let(:frozen_time) { Time.zone.parse("2025-06-15 12:30:00") }
  let!(:device) { create(:ds18b20, name: "Chart Sensor", value_decimal: 22.5, log_enabled: true) }
  let!(:public_panel) { create(:panel, name: "Public Chart Panel", public_access: true) }
  let!(:private_panel) { create(:panel, name: "Private Chart Panel", public_access: false) }
  let!(:public_widget) do
    create(:widget, :type_chart, panel: public_panel, device: device, time_window_hours: 24)
  end
  let!(:private_widget) do
    create(:widget, :type_chart, panel: private_panel, device: device, time_window_hours: 24)
  end

  before do
    create(:device_log, :with_decimal_value, device: device, value_decimal: 10.0,
      created_at: frozen_time - 2.hours)
    create(:device_log, :with_decimal_value, device: device, value_decimal: 15.0,
      created_at: frozen_time - 1.hour)
    create(:device_log, :with_decimal_value, device: device, value_decimal: 5.0,
      created_at: frozen_time - 30.hours)
  end

  it "returns series data for a public panel without authentication" do
    Timecop.freeze(frozen_time) do
      get panel_widget_chart_path(public_panel, public_widget)
      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data).to be_an(Array)
      expect(data.first).to be_an(Array)
      values = data.map { |point| point.last.to_f }
      expect(values).to include(10.0, 15.0, 22.5)
      expect(values).to include(5.0)
    end
  end

  it "prepends the last value before the window and appends the current device value" do
    Timecop.freeze(frozen_time) do
      get panel_widget_chart_path(public_panel, public_widget)
      data = JSON.parse(response.body)
      expect(data.first.last.to_f).to eq(5.0)
      expect(Time.zone.parse(data.first.first)).to be_within(1.second).of(frozen_time - 24.hours)
      expect(data.last.last.to_f).to eq(22.5)
      expect(Time.zone.parse(data.last.first)).to be_within(1.second).of(frozen_time)
    end
  end

  it "returns 0/1 values for boolean devices" do
    board = create(:board, name: "Bool Board", ip: "192.168.1.210")
    bool_device = create(:relay, name: "Bool Chart", board: board, pin: 8, value_boolean: true, log_enabled: true)
    widget = create(:widget, :type_chart, panel: public_panel, device: bool_device, time_window_hours: 6)

    Timecop.freeze(frozen_time) do
      create(:device_log, :with_boolean_value, device: bool_device, value_boolean: false,
        created_at: frozen_time - 1.hour)
      create(:device_log, :with_boolean_value, device: bool_device, value_boolean: true,
        created_at: frozen_time - 30.minutes)

      get panel_widget_chart_path(public_panel, widget)
      expect(response).to have_http_status(:ok)
      values = JSON.parse(response.body).map(&:last)
      expect(values).to include(0, 1)
      expect(values).to all(be_in([0, 1]))
    end
  end

  it "returns only the current value when the device has no logs" do
    board = create(:board, name: "Empty Board", ip: "192.168.1.211")
    empty_device = create(:ds18b20, name: "Empty Sensor", board: board, pin: 4, value_decimal: 18.0, log_enabled: true)
    widget = create(:widget, :type_chart, panel: public_panel, device: empty_device, time_window_hours: 12)

    Timecop.freeze(frozen_time) do
      get panel_widget_chart_path(public_panel, widget)
      data = JSON.parse(response.body)
      expect(data.length).to eq(1)
      expect(data.first.last.to_f).to eq(18.0)
    end
  end

  it "returns 401 for a private panel without authentication" do
    get panel_widget_chart_path(private_panel, private_widget)
    expect(response).to have_http_status(:unauthorized)
  end

  it "returns 404 for a non-chart widget" do
    text_widget = create(:widget, :type_text_value, panel: public_panel, device: device)
    get panel_widget_chart_path(public_panel, text_widget)
    expect(response).to have_http_status(:not_found)
  end

  it "returns 404 when the widget belongs to another panel" do
    get panel_widget_chart_path(public_panel, private_widget)
    expect(response).to have_http_status(:not_found)
  end
end
