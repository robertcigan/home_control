require "rails_helper"

RSpec.feature "Boards", type: :feature do
  let!(:arduino_board) { create(:board, name: "Arduino Mega", ip: "192.168.1.10") }
  let!(:esp_board) { create(:board, :with_wifi, name: "ESP32 Board", ip: "192.168.1.20") }
  let!(:modbus_board) { create(:board, :modbus_tcp, name: "Modbus TCP", ip: "192.168.1.30") }

  describe "index page" do
    scenario "displays all boards", js: true do
      visit boards_path
      expect(page).to have_content("Boards")
      expect(page).to have_content("Arduino Mega")
      expect(page).to have_content("ESP32 Board")
      expect(page).to have_content("Modbus TCP")
    end

    scenario "filters boards by name or IP", js: true do
      visit boards_path
      fill_in "Search by Name or IP", with: "Arduino"
      expect(page).to have_content("Arduino Mega")
      expect(page).not_to have_content("ESP32 Board")
      expect(page).not_to have_content("Modbus TCP")
    end

    scenario "shows pagination controls" do
      15.times { |i| create(:board, name: "Board #{i}", ip: "192.168.1.#{100 + i}") }
      visit boards_path
      expect(page).to have_selector(".page-pagination")
    end
  end

  describe "creating boards via modal" do
    scenario "creates an Arduino Mega board", js: true do
      visit boards_path
      click_link "Add Board"
      within "#ajax-modal" do
        fill_in "Name", with: "New Arduino Board"
        fill_in "IP", with: "192.168.1.100"
        select "Arduino Mega (8bit)", from: "Type"
        expect(page).to have_field("Clear Logs After (days)")
        fill_in "Clear Logs After (days)", with: "30"
        click_button "Create"
      end
      expect(page).to have_content("Board was successfully created")
      expect(page).to have_content("New Arduino Board")
      board = Board.find_by(name: "New Arduino Board")
      expect(board.ip).to eq("192.168.1.100")
      expect(board.board_type).to eq("arduino_mega_8b")
      expect(board.days_to_preserve_logs).to eq(30)
    end

    scenario "creates an ESP board", js: true do
      visit boards_path
      click_link "Add Board"
      within "#ajax-modal" do
        fill_in "Name", with: "New ESP Board"
        fill_in "IP", with: "192.168.1.101"
        select "ESP8266/ESP32", from: "Type"
        wait_for_modal_reload
        fill_in "Clear Logs After (days)", with: "30"
        click_button "Create"
      end
      expect(page).to have_content("Board was successfully created")
      expect(page).to have_content("New ESP Board")
      board = Board.find_by(name: "New ESP Board")
      expect(board.ip).to eq("192.168.1.101")
      expect(board.board_type).to eq(Board::BoardType::ESP)
      expect(board.days_to_preserve_logs).to eq(30)
    end

    scenario "creates a Modbus TCP board with required fields", js: true do
      visit boards_path
      click_link "Add Board"
      within "#ajax-modal" do
        fill_in "Name", with: "New Modbus Board"
        fill_in "IP", with: "192.168.1.102"
        select "ModBus TCP", from: "Type"
        fill_in "ModBus Address", with: "2"
        fill_in "Read Interval (s)", with: "1000"
        fill_in "Clear Logs After (days)", with: "30"
        click_button "Create"
      end
      expect(page).to have_content("Board was successfully created")
      expect(page).to have_content("New Modbus Board")
      board = Board.find_by(name: "New Modbus Board")
      expect(board.ip).to eq("192.168.1.102")
      expect(board.board_type).to eq(Board::BoardType::MODBUS_TCP)
      expect(board.slave_address).to eq(2)
      expect(board.data_read_interval).to eq(1000)
      expect(board.days_to_preserve_logs).to eq(30)
    end

    scenario "shows validation errors for invalid data", js: true do
      visit boards_path
      click_link "Add Board"
      within "#ajax-modal" do
        click_button "Create"
      end
      expect(page).to have_content("can't be blank")
    end
  end

  describe "editing boards via modal" do
    scenario "edits an existing board", js: true do
      visit boards_path
      click_link "Edit", href: edit_board_path(arduino_board)
      within "#ajax-modal" do
        fill_in "Name", with: "Updated Arduino Board"
        click_button "Update"
      end
      expect(page).to have_content("Board was successfully updated")
      expect(page).to have_content("Updated Arduino Board")

      # Verify the board was updated in database with correct values
      arduino_board.reload
      expect(arduino_board.name).to eq("Updated Arduino Board")
    end

    scenario "edits a Modbus board with additional fields", js: true do
      visit boards_path
      click_link "Edit", href: edit_board_path(modbus_board)
      within "#ajax-modal" do
        fill_in "ModBus Address", with: "3"
        fill_in "Read Interval (s)", with: "2000"
        click_button "Update"
      end
      expect(page).to have_content("Board was successfully updated")
      modbus_board.reload
      expect(modbus_board.slave_address).to eq(3)
      expect(modbus_board.data_read_interval).to eq(2000)
    end
  end

  describe "removing boards" do
    scenario "removes a board", js: true do
      visit boards_path
      find("a[href='#{board_path(arduino_board)}'][data-method='delete']").click
      within "#confirm-modal" do
        click_link "Confirm"
      end
      expect(page).to have_content("Board was successfully removed")
      expect(page).not_to have_content("Arduino Mega")
    end
  end

  describe "show page" do
    scenario "displays board details", js: true do
      visit board_path(arduino_board)
      expect(page).to have_content("Arduino Mega")
      expect(page).to have_content("192.168.1.10")
      expect(page).to have_content("Arduino Mega (8bit)")
    end

    scenario "displays ESP board with WiFi details", js: true do
      esp_board.update!(connected_at: Time.current, ssid: "TestWiFi", signal_strength: 85)
      visit board_path(esp_board)
      expect(page).to have_content("ESP32 Board")
      expect(page).to have_content("ESP8266/ESP32")
      expect(page).to have_content("TestWiFi")
      expect(page).to have_content("85")
    end

    scenario "displays Modbus board with additional details", js: true do
      visit board_path(modbus_board)
      expect(page).to have_content("ModBus TCP")
      expect(page).to have_content("Address")
      expect(page).to have_content("1")
    end
  end

  describe "ActionCable realtime updates" do
    scenario "updates connected state on index when board connects", js: true do
      esp_board.update!(connected_at: nil, ssid: nil, signal_strength: nil)
      visit boards_path
      board_row = find("tr.board", text: "ESP32 Board")
      esp_board.update!(connected_at: Time.current, ssid: "NewWiFi", signal_strength: 42)
      expect(board_row.find(".ssid")).to have_content("NewWiFi", wait: 10)
      expect(board_row.find(".signal-strength")).to have_content("42", wait: 10)
    end

    scenario "updates connected state on index when board disconnects", js: true do
      esp_board.update!(connected_at: Time.current, ssid: "TestWiFi", signal_strength: 80)
      visit boards_path
      board_row = find("tr.board", text: "ESP32 Board")
      expect(board_row.find(".ssid")).to have_content("TestWiFi")
      esp_board.update!(connected_at: nil, ssid: nil, signal_strength: nil)
      expect(board_row.find(".ssid")).to have_text("", wait: 10)
      expect(board_row.find(".signal-strength")).to have_text("", wait: 10)
    end

    scenario "updates connected state on show page over cable", js: true do
      esp_board.update!(connected_at: nil, ssid: nil, signal_strength: nil)
      visit board_path(esp_board)
      card = find(".card.board")
      esp_board.update!(connected_at: Time.current, ssid: "LiveWiFi", signal_strength: 55)
      expect(card.find(".ssid")).to have_content("LiveWiFi", wait: 10)
      expect(card.find(".signal-strength")).to have_content("55", wait: 10)
    end
  end

  describe "reload form round-trip" do
    scenario "preserves entered values when board type changes without creating a record", js: true do
      visit boards_path
      click_link "Add Board"
      within "#ajax-modal" do
        fill_in "Name", with: "Reload Test Board"
        fill_in "IP", with: "192.168.1.200"
        select "ESP8266/ESP32", from: "Type"
        wait_for_modal_reload
        expect(page).to have_field("Name", with: "Reload Test Board")
        expect(page).to have_field("IP", with: "192.168.1.200")
      end
      expect(Board.find_by(name: "Reload Test Board")).to be_nil
    end
  end
end