require "rails_helper"

RSpec.feature "Chart widgets", type: :feature do
  let!(:arduino_board) { create(:board, name: "Arduino Board", ip: "192.168.1.10") }
  let!(:sensor) do
    create(:ds18b20, name: "Temp Sensor", board: arduino_board, pin: 2, value_decimal: 21.5, log_enabled: true)
  end
  let!(:no_log_sensor) do
    create(:ds18b20, name: "No Log Sensor", board: arduino_board, pin: 3, value_decimal: 19.0, log_enabled: false)
  end
  let!(:public_panel) { create(:panel, name: "Public Chart Panel", public_access: true) }
  let!(:private_panel) { create(:panel, name: "Private Chart Panel", public_access: false) }

  before do
    create(:device_log, :with_decimal_value, device: sensor, value_decimal: 20.0, created_at: 1.hour.ago)
  end

  describe "panel rendering" do
    scenario "renders chart widget on a public panel", js: true do
      create(:widget, :type_chart, panel: public_panel, device: sensor, show_label: true, time_window_hours: 24)
      visit panel_path(public_panel)
      expect(page).to have_css(".widget-chart .chart-canvas")
      expect(page).to have_css(".widget-chart[data-chart-points]", wait: 10)
      points = find(".widget-chart")["data-chart-points"].to_i
      expect(points).to be > 0
    end

    scenario "does not load chart data on a private panel without authentication", js: true do
      create(:widget, :type_chart, panel: private_panel, device: sensor, show_label: true, time_window_hours: 24)
      visit panel_path(private_panel)
      expect(page).to have_css(".widget-chart .chart-canvas")
      expect(page).to have_no_css(".widget-chart[data-chart-points]", wait: 2)
    end

    scenario "appends a live point when the device value changes", js: true do
      create(:widget, :type_chart, panel: public_panel, device: sensor, show_label: true, time_window_hours: 24)
      visit panel_path(public_panel)
      expect(page).to have_css(".widget-chart[data-chart-points]", wait: 10)
      initial_points = find(".widget-chart")["data-chart-points"].to_i
      wait_for_action_cable
      sensor.update(value_decimal: 33.3)
      expect(page).to have_css(".widget-chart[data-chart-points='#{initial_points + 1}']", wait: 10)
    end
  end

  describe "widget form" do
    scenario "shows time window field for chart type with default 24", js: true do
      visit new_panel_widget_path(public_panel)
      select_tom "Chart"
      wait_for_form_reload
      expect(page).to have_field("Time Window (hours)", with: "24.0")
      expect_tom_select_selected("Chart Type", selected: "Auto")
    end

    scenario "rejects a device without logging enabled", js: true do
      visit new_panel_widget_path(public_panel)
      select_tom "Chart"
      wait_for_form_reload
      select_tom "No Log Sensor", from: "Device"
      fill_in "Time Window (hours)", with: "12"
      click_button "Create"
      expect(page).to have_content("must have logging enabled to draw a chart")
    end

    scenario "creates a chart widget with a log-enabled device", js: true do
      visit new_panel_widget_path(public_panel)
      select_tom "Chart"
      wait_for_form_reload
      select_tom "Temp Sensor", from: "Device"
      fill_in "Time Window (hours)", with: "12"
      click_button "Create"
      expect(page).to have_content("Widget was successfully created")
      widget = public_panel.widgets.last
      expect(widget.widget_type).to eq("chart")
      expect(widget.time_window_hours).to eq(12)
      expect(widget.device).to eq(sensor)
    end
  end
end
