require "rails_helper"

RSpec.feature "Device Logs", type: :feature do
  let!(:board) { create(:board, name: "Test Board", ip: "192.168.1.100") }

  describe "boolean device history chart" do
    let!(:device) { create(:relay, name: "Relay Device", board: board, pin: 1, log_enabled: true) }
    let!(:older_log) { create(:device_log, :with_boolean_value, device: device, value_boolean: false, created_at: 1.hour.ago) }
    let!(:newer_log) { create(:device_log, :with_boolean_value, device: device, value_boolean: true, created_at: 30.minutes.ago) }

    scenario "displays value history chart with navigation", js: true do
      visit device_path(device)
      expect(page).to have_css("#device_history", wait: 10)
      expect(page).to have_css(".chart-canvas canvas", wait: 10)
    end

    scenario "navigates chart by selecting different time intervals", js: true do
      visit device_path(device)
      expect(page).to have_css("#device_history", wait: 10)
      expect(page).to have_button("Year")
      expect(page).to have_button("Month")
      expect(page).to have_button("Week")
      expect(page).to have_button("Day")
      expect(page).to have_button("Hour")

      click_button "Week"
      expect(page).to have_selector(".nav-link.active", text: "Week")
      expect(page).to have_css(".chart-canvas canvas")
      click_button "Month"
      expect(page).to have_selector(".nav-link.active", text: "Month")
      expect(page).to have_css(".chart-canvas canvas")
    end

    scenario "navigates chart by moving through days", js: true do
      Timecop.freeze(Time.parse("2025-01-01 12:00:00")) do
        visit device_path(device)
        expect(page).to have_css("#device_history")
        click_button "Day"
        expect(page).to have_css(".btn.btn-success", text: "1.1.2025")
        within "ul.nav.nav-tabs li.ms-auto" do
          find("button.btn.btn-secondary.me-2").click
        end
        expect(page).to have_selector(".btn.btn-disabled.btn-success", text: "31.12.2024")
        within "ul.nav.nav-tabs li.ms-auto" do
          find("button.btn.btn-secondary.ms-2").click
        end
        expect(page).to have_selector(".btn.btn-disabled.btn-success", text: "1.1.2025")
        expect(page).to have_css(".chart-canvas canvas")
      end
    end

    scenario "navigates chart by moving through hours", js: true do
      Timecop.freeze(Time.parse("2025-01-01 12:00:00")) do
        visit device_path(device)
        expect(page).to have_css("#device_history")
        click_button "Hour"
        expect(page).to have_selector(".btn.btn-disabled.btn-success", text: "1.1.2025 12h")
        within "ul.nav.nav-tabs li.ms-auto" do
          find("button.btn.btn-secondary.me-2").click
        end
        expect(page).to have_selector(".btn.btn-disabled.btn-success", text: "1.1.2025 11h")
        within "ul.nav.nav-tabs li.ms-auto" do
          find("button.btn.btn-secondary.ms-2").click
        end
        expect(page).to have_selector(".btn.btn-success", text: "1.1.2025 12h")
        expect(page).to have_css(".chart-canvas canvas")
      end
    end
  end

  describe "decimal device history chart" do
    let!(:device) { create(:analog_input, name: "Analog Device", board: board, pin: 2, log_enabled: true) }
    let!(:log) { create(:device_log, :with_decimal_value, device: device, value_decimal: 25.5, created_at: 1.hour.ago) }

    scenario "displays line chart for numeric device", js: true do
      visit device_path(device)
      expect(page).to have_css("#device_history", wait: 10)
      expect(page).to have_css(".chart-canvas canvas", wait: 10)
    end
  end

  describe "string device history chart" do
    let!(:device) { create(:virtual_string, name: "String Device", log_enabled: true) }
    let!(:log) { create(:device_log, :with_string_value, device: device, value_string: "hello", created_at: 1.hour.ago) }

    scenario "displays chart for string device", js: true do
      visit device_path(device)
      expect(page).to have_css("#device_history", wait: 10)
      expect(page).to have_css(".chart-canvas canvas", wait: 10)
    end
  end

  describe "device logs table" do
    let!(:device) { create(:relay, name: "Logged Relay", board: board, pin: 3, log_enabled: true) }
    let!(:off_log) { create(:device_log, :with_boolean_value, device: device, value_boolean: false, created_at: 1.hour.ago) }
    let!(:on_log) { create(:device_log, :with_boolean_value, device: device, value_boolean: true, created_at: 30.minutes.ago) }

    scenario "displays device logs", js: true do
      visit device_path(device)
      expect(page).to have_css("#device_logs table", wait: 10)
      within "#device_logs" do
        expect(page).to have_content("off")
        expect(page).to have_content("on")
      end
    end

    scenario "sorts device logs without page reload", js: true do
      visit device_path(device)
      within "#device_logs" do
        expect(page).to have_content("off")
        expect(page).to have_content("on")
      end
      within "#device_logs" do
        click_link "Time"
      end
      within "#device_logs table tbody tr:nth-child(1)" do
        expect(page).to have_content("off")
      end
      within "#device_logs" do
        click_link "Value"
      end
      within "#device_logs table tbody tr:nth-child(1)" do
        expect(page).to have_content("off")
      end
    end

    scenario "paginates device logs without page reload", js: true do
      20.times do |i|
        create(:device_log,
          :with_boolean_value,
          device: device,
          value_boolean: i.even?,
          created_at: (i + 3).hours.ago
        )
      end

      visit device_path(device)
      within "#device_logs" do
        expect(page).to have_selector(".page-pagination")
        expect(page).to have_content("Displaying device logs 1 - 20 of")
      end
      within "#device_logs .page-pagination" do
        click_link "2"
      end
      within "#device_logs" do
        expect(page).to have_content("Displaying device logs 21 -")
      end
    end
  end

  describe "logging disabled" do
    let!(:device) { create(:relay, name: "No Logs Relay", board: board, pin: 4, log_enabled: false) }

    scenario "hides chart and log table when logging is disabled", js: true do
      visit device_path(device)
      expect(page).not_to have_css("#device_history")
      expect(page).not_to have_css("#device_logs")
    end
  end
end
