require "rails_helper"

RSpec.feature "Board Logs", type: :feature do
  let!(:board) { create(:board, name: "Test Board", ip: "192.168.1.100") }

  let!(:connected_log) { create(:board_log, board: board, connected: true, ssid: "TestWiFi", signal_strength: 85, created_at: 1.hour.ago) }
  let!(:disconnected_log) { create(:board_log, board: board, connected: false, ssid: nil, signal_strength: nil, created_at: 30.minutes.ago) }
  let!(:reconnected_log) { create(:board_log, board: board, connected: true, ssid: "TestWiFi", signal_strength: 90, created_at: 15.minutes.ago) }

  describe "connection history chart" do
    scenario "displays connection history chart with navigation", js: true do
      visit board_path(board)
      expect(page).to have_css(".sk-spinner", visible: false, wait: 10)
      expect(page).to have_css("#board_history")
      expect(page).to have_css("canvas")
    end

    scenario "navigates chart by selecting different time intervals", js: true do
      visit board_path(board)
      expect(page).to have_css("#board_history")
      expect(page).to have_link("Year")
      expect(page).to have_link("Month")
      expect(page).to have_link("Week")
      expect(page).to have_link("Day")
      expect(page).to have_link("Hour")

      click_link "Week"
      expect(page).to have_selector(".nav-link.active", text: "Week")
      click_link "Month"
      expect(page).to have_selector(".nav-link.active", text: "Month")
    end

    scenario "navigates chart by moving through days", js: true do
      Timecop.freeze(Time.parse("2025-01-01 12:00:00")) do
        visit board_path(board)
        expect(page).to have_css("#board_history")
        click_link "Day"
        expect(page).to have_css(".btn.btn-success", text: "1.1.2025")
        within "ul.nav.nav-tabs li.ml-auto" do
          find("a.btn.btn-secondary.mr-2").click
        end
        expect(page).to have_selector(".btn.btn-disabled.btn-success", text: "31.12.2024")
        within "ul.nav.nav-tabs li.ml-auto" do
          find("a.btn.btn-secondary.ml-2").click
        end
        expect(page).to have_selector(".btn.btn-disabled.btn-success", text: "1.1.2025")
      end
    end

    scenario "navigates chart by moving through hours", js: true do
      Timecop.freeze(Time.parse("2025-01-01 12:00:00")) do
        visit board_path(board)
        expect(page).to have_css("#board_history")
        click_link "Hour"
        expect(page).to have_selector(".btn.btn-disabled.btn-success", text: "1.1.2025 12h")
        within "ul.nav.nav-tabs li.ml-auto" do
          find("a.btn.btn-secondary.mr-2").click
        end
        expect(page).to have_selector(".btn.btn-disabled.btn-success", text: "1.1.2025 11h")
        within "ul.nav.nav-tabs li.ml-auto" do
          find("a.btn.btn-secondary.ml-2").click
        end
        expect(page).to have_selector(".btn.btn-success", text: "1.1.2025 12h")
      end
    end
  end

  describe "connection logs" do
    scenario "displays connection logs with filtering", js: true do
      visit board_path(board)
      expect(page).to have_css(".sk-spinner", visible: false, wait: 10)
      within "#board_logs" do
        within "table tbody tr:nth-child(1)" do
          expect(page).to have_content("connected")
        end
        within "table tbody tr:nth-child(2)" do
          expect(page).to have_content("disconnected")
        end
      end
    end

    scenario "filters connection logs without page reload", js: true do
      visit board_path(board)
      within "#board_logs" do
        expect(page).to have_content("connected")
        expect(page).to have_content("disconnected")
      end
      select "Connected", from: "q_connected_eq"
      within "#board_logs" do
      expect(page).not_to have_content("disconnected")
      expect(page).to have_content("connected")

      end
    end

    scenario "paginates connection logs without page reload", js: true do
      15.times do |i|
        create(:board_log,
          board: board,
          connected: [true, false].sample,
          created_at: i.hours.ago
        )
      end

      visit board_path(board)
      within "#board_logs" do
        expect(page).to have_selector(".page-pagination")
        expect(page).to have_content("Displaying all 18 board logs")
      end
    end

    scenario "sorts logs by different columns", js: true do
      visit board_path(board)
      within "#board_logs" do
        click_link "Time"
        expect(page).to have_selector("table")
        click_link "Status"
        expect(page).to have_selector("table")
      end
    end
  end
end