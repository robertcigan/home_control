require "rails_helper"

RSpec.feature "Devices index", type: :feature do
  include_context "devices feature setup"

  describe "index page" do
    scenario "displays all devices", js: true do
      visit devices_path
      expect(page).to have_content("Devices")
      expect(page).to have_content("Test Switch")
      expect(page).to have_content("Test Arduino Relay")
      expect(page).to have_content("Test Analog")
    end

    scenario "filters devices by name", js: true do
      visit devices_path
      fill_in "Search by Name", with: "Switch"
      expect(page).to have_content("Test Switch")
      expect(page).not_to have_content("Test Arduino Relay")
      expect(page).not_to have_content("Test Analog")
    end

    scenario "filters devices by pin", js: true do
      visit devices_path
      fill_in "Search by Pin", with: "1"
      expect(page).to have_no_content("Test Arduino Relay")
      expect(page).to have_no_content("Test Analog")
      expect(page).to have_no_content("Test Relay ESP")
      expect(page).to have_content("Test Switch")
    end

    scenario "filters devices by type", js: true do
      visit devices_path
      select "Switch", from: "q_device_type_in"
      expect(page).to have_no_content("Test Arduino Relay")
      expect(page).to have_content("Test Switch")
      expect(page).to have_no_content("Test Relay")
      expect(page).to have_no_content("Test Analog")
    end

    scenario "filters devices by board", js: true do
      visit devices_path
      select "ESP Board", from: "q_board_id_eq"
      expect(page).to have_no_content("Test Switch")
      expect(page).to have_no_content("Test Analog")
      expect(page).to have_no_content("Test Arduino Relay")
      expect(page).to have_content("Test ESP Relay")
    end

    scenario "shows pagination controls", js: true do
      25.times { |i| create(:switch, name: "Device #{i}", board: arduino_board, pin: i + 10) }
      visit devices_path
      expect(page).to have_selector(".page-pagination")
      expect(page).to have_css("table tbody tr", count: 20)
      within ".page-pagination" do
        click_link "2"
      end
      expect(page).to have_css("table tbody tr", count: 9)
    end

    scenario "persists per-page selection across visits", js: true do
      55.times { |i| create(:switch, name: "Per Page #{i}", board: arduino_board, pin: i + 50) }
      visit devices_path
      expect(page).to have_css("table tbody tr", count: 20)
      find("select#per").find(:option, "50").select_option
      expect(page).to have_css("table tbody tr", count: 50, wait: 10)
      visit devices_path
      expect(page).to have_css("table tbody tr", count: 50, wait: 10)
    end
  end

  describe "show page" do
    scenario "displays device details", js: true do
      visit devices_path
      within "table tbody tr:nth-child(1)" do
        click_link "Test Analog"
      end
      expect(page).to have_content("Test Analog\n \nType\nAnalog Input\nBoard\nArduino Board\nPin/Address\n3\nPoll\n1000ms")
    end

    scenario "displays Modbus device details", js: true do
      modbus_device = create(:virtual_boolean, :modbus_writable, name: "Modbus Device", board: modbus_board)
      visit device_path(modbus_device)
      expect(page).to have_content("Device\n \nType\nVirtual Boolean\nBoard\nModbus Board\nPin/Address\n1\nHolding Register\n1\nModBus Data Type\nuint16\nValue Scale\n1\nValue\nfalse")
   end
  end
end
