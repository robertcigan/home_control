require "rails_helper"

RSpec.feature "Devices", type: :feature do
  let!(:arduino_board) { create(:board, name: "Arduino Board", ip: "192.168.1.10") }
  let!(:esp_board) { create(:board, :with_wifi, name: "ESP Board", ip: "192.168.1.20") }
  let!(:modbus_board) { create(:board, :modbus_tcp, name: "Modbus Board", ip: "192.168.1.30") }

  let!(:switch_device) { create(:switch, name: "Test Switch", board: arduino_board, pin: 1) }
  let!(:relay_device) { create(:relay, name: "Test Arduino Relay", board: arduino_board, pin: 2) }
  let!(:analog_device) { create(:analog_input, name: "Test Analog", board: arduino_board, pin: 3) }
  let!(:esp_relay_device) { create(:relay, name: "Test ESP Relay", board: esp_board, pin: 4) }

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
  end

  describe "creating devices via modal" do
    scenario "creates a Switch device", js: true do
      visit devices_path
      click_link "Add Device"
      within "#ajax-modal" do
        fill_in "Name", with: "New Switch"
        select "Arduino Board", from: "Board"
        wait_for_modal_reload
        select "Switch", from: "Type"
        wait_for_modal_reload
        expect(page).to have_field("Inverted")
        expect(page).to have_field("Pin/Address", visible: :visible)
        fill_in "Pin/Address", with: "4"
        check "Inverted"
        check "Log Enabled"
        fill_in "Clear Logs After (days)", with: "30"
        click_button "Create"
      end
      expect(page).to have_content("Device was successfully created")
      expect(page).to have_content("New Switch")
      device = Device.find_by(name: "New Switch")
      expect(device.device_type).to eq("Device::Switch")
      expect(device.board).to eq(arduino_board)
      expect(device.pin).to eq(4)
      expect(device.inverted).to be true
      expect(device.log_enabled).to be true
      expect(device.days_to_preserve_logs).to eq(30)
    end

    scenario "creates a Relay device", js: true do
      visit devices_path
      click_link "Add Device"
      within "#ajax-modal" do
        fill_in "Name", with: "New Relay"
        select "Arduino Board", from: "Board"
        wait_for_modal_reload
        expect(page).to have_select("Board", selected: "Arduino Board")
        select "Relay", from: "Type"
        wait_for_modal_reload
        expect(page).to have_select("Type", selected: "Relay")
        expect(page).to have_field("Inverted")
        expect(page).to have_field("Pin/Address", visible: :visible)
        fill_in "Pin/Address", with: "5"
        check "Inverted"
        click_button "Create"
      end
      expect(page).to have_content("Device was successfully created")
      expect(page).to have_content("New Relay")
      device = Device.find_by(name: "New Relay")
      expect(device.device_type).to eq("Device::Relay")
      expect(device.pin).to eq(5)
      expect(device.inverted).to be true
    end

    scenario "creates an Analog Input device", js: true do
      visit devices_path
      click_link "Add Device"
      within "#ajax-modal" do
        fill_in "Name", with: "New Analog"
        select "Arduino Board", from: "Board"
        wait_for_modal_reload
        select "Analog Input", from: "Type"
        wait_for_modal_reload
        expect(page).to have_field("Pin/Address")
        fill_in "Pin/Address", with: "5"
        fill_in "Poll", with: "500"
        fill_in "Unit", with: "V"
        click_button "Create"
      end
      expect(page).to have_content("Device was successfully created")
      expect(page).to have_content("New Analog")
      device = Device.find_by(name: "New Analog")
      expect(device.device_type).to eq("Device::AnalogInput")
      expect(device.pin).to eq(5)
      expect(device.poll).to eq(500)
      expect(device.unit).to eq("V")
    end

    scenario "creates a Button device", js: true do
      visit devices_path
      click_link "Add Device"
      within "#ajax-modal" do
        fill_in "Name", with: "New Button"
        select "Arduino Board", from: "Board"
        wait_for_modal_reload
        select "Button", from: "Type"
        wait_for_modal_reload
        expect(page).to have_field("Inverted")
        expect(page).to have_field("Pin/Address")
        fill_in "Pin/Address", with: "5"
        check "Inverted"
        click_button "Create"
      end
      expect(page).to have_content("Device was successfully created")
      expect(page).to have_content("New Button")
      device = Device.find_by(name: "New Button")
      expect(device.device_type).to eq("Device::Button")
      expect(device.pin).to eq(5)
      expect(device.inverted).to be true
    end

    scenario "creates a PWM device", js: true do
      visit devices_path
      click_link "Add Device"
      within "#ajax-modal" do
        fill_in "Name", with: "New PWM"
        select "Arduino Board", from: "Board"
        wait_for_modal_reload
        select "PWM output", from: "Type"
        wait_for_modal_reload
        expect(page).to have_field("Pin/Address")
        fill_in "Pin/Address", with: "5"
        fill_in "Value", with: "50"
        click_button "Create"
      end
      expect(page).to have_content("Device was successfully created")
      expect(page).to have_content("New PWM")
      device = Device.find_by(name: "New PWM")
      expect(device.device_type).to eq("Device::Pwm")
      expect(device.pin).to eq(5)
      expect(device.value_integer).to eq(50)
    end

    scenario "creates a DS18B20 Temperature Sensor", js: true do
      visit devices_path
      click_link "Add Device"
      within "#ajax-modal" do
        fill_in "Name", with: "New Temp Sensor"
        select "Arduino Board", from: "Board"
        wait_for_modal_reload
        expect(page).to have_select("Board", selected: "Arduino Board")
        select "DS18B20 Temperature Sensor", from: "Type"
        wait_for_modal_reload
        expect(page).to have_select("Type", selected: "DS18B20 Temperature Sensor")
        expect(page).to have_field("Poll")
        expect(page).to have_field("Pin/Address")
        fill_in "Pin/Address", with: "5"
        expect(find_field("Pin/Address").value).to eq("5")
        fill_in "Unit", with: "°C"
        click_button "Create"
      end
      expect(page).to have_content("Device was successfully created")
      expect(page).to have_content("New Temp Sensor")
      device = Device.find_by(name: "New Temp Sensor")
      expect(device.device_type).to eq("Device::Ds18b20")
      expect(device.pin).to eq(5)
      expect(device.unit).to eq("°C")
    end

    scenario "creates a Distance Sensor", js: true do
      visit devices_path
      click_link "Add Device"
      within "#ajax-modal" do
        fill_in "Name", with: "New Distance"
        select "Arduino Board", from: "Board"
        wait_for_modal_reload
        select "Distance", from: "Type"
        wait_for_modal_reload
        expect(page).to have_field("Poll")
        expect(page).to have_field("Pin/Address")
        fill_in "Pin/Address", with: "5"
        expect(find_field("Pin/Address").value).to eq("5")
        fill_in "Unit", with: "cm"
        click_button "Create"
      end
      expect(page).to have_content("Device was successfully created")
      expect(page).to have_content("New Distance")
      device = Device.find_by(name: "New Distance")
      expect(device.device_type).to eq("Device::Distance")
      expect(device.pin).to eq(5)
      expect(device.unit).to eq("cm")
    end

    scenario "creates a Curtain/Blinds device", js: true do
      visit devices_path
      click_link "Add Device"
      within "#ajax-modal" do
        fill_in "Name", with: "New Curtain"
        select "Arduino Board", from: "Board"
        wait_for_modal_reload
        select "Blinds/Shutter/Curtain", from: "Type"
        wait_for_modal_reload
        expect(page).to have_field("Inverted")
        expect(page).to have_field("Pin/Address")
        fill_in "Pin/Address", with: "5"
        check "Inverted"
        click_button "Create"
      end
      expect(page).to have_content("Device was successfully created")
      expect(page).to have_content("New Curtain")
      device = Device.find_by(name: "New Curtain")
      expect(device.device_type).to eq("Device::Curtain")
      expect(device.pin).to eq(5)
      expect(device.inverted).to be true
    end

    scenario "creates a Sound device", js: true do
      visit devices_path
      click_link "Add Device"
      within "#ajax-modal" do
        fill_in "Name", with: "New Sound"
        select "Arduino Board", from: "Board"
        select "Sound", from: "Type"
        expect(page).to have_field("Pin/Address")
        fill_in "Pin/Address", with: "5"
        click_button "Create"
      end
      expect(page).to have_content("Device was successfully created")
      expect(page).to have_content("New Sound")
      device = Device.find_by(name: "New Sound")
      expect(device.device_type).to eq("Device::Sound")
      expect(device.pin).to eq(5)
    end

    scenario "creates a Board Test device", js: true do
      visit devices_path
      click_link "Add Device"
      within "#ajax-modal" do
        fill_in "Name", with: "New Board Test"
        select "Arduino Board", from: "Board"
        wait_for_modal_reload
        select "Board Test", from: "Type"
        wait_for_modal_reload
        expect(page).to have_field("Pin/Address")
        fill_in "Pin/Address", with: "10"
        click_button "Create"
      end
      expect(page).to have_content("Device was successfully created")
      expect(page).to have_content("New Board Test")
      device = Device.find_by(name: "New Board Test")
      expect(device.device_type).to eq("Device::BoardTest")
      expect(device.pin).to eq(10)
    end
  end

  describe "creating virtual devices" do
    scenario "creates a Virtual Boolean device", js: true do
      visit devices_path
      click_link "Add Device"
      within "#ajax-modal" do
        fill_in "Name", with: "New Virtual Boolean"
        select "Virtual Boolean", from: "Type"
        check "Value boolean"
        fill_in "Unit", with: "V"
        click_button "Create"
      end
      expect(page).to have_content("Device was successfully created")
      expect(page).to have_content("New Virtual Boolean")
      device = Device.find_by(name: "New Virtual Boolean")
      expect(device.device_type).to eq("Device::VirtualBoolean")
      expect(device.unit).to eq("V")
      expect(device.value_boolean).to be true
    end

    scenario "creates a Virtual Decimal device", js: true do
      visit devices_path
      click_link "Add Device"
      within "#ajax-modal" do
        fill_in "Name", with: "New Virtual Decimal"
        select "Virtual Decimal", from: "Type"
        expect(page).to have_no_field("Writable?")
        fill_in "Value", with: "3.14"
        fill_in "Unit", with: "V"
        click_button "Create"
      end
      expect(page).to have_content("Device was successfully created")
      expect(page).to have_content("New Virtual Decimal")
      device = Device.find_by(name: "New Virtual Decimal")
      expect(device.device_type).to eq("Device::VirtualDecimal")
      expect(device.value_decimal).to eq(3.14)
      expect(device.unit).to eq("V")
    end

    scenario "creates a Virtual Integer device", js: true do
      visit devices_path
      click_link "Add Device"
      within "#ajax-modal" do
        fill_in "Name", with: "New Virtual Integer"
        select "Virtual Integer", from: "Type"
        expect(page).to have_no_field("Writable?")
        fill_in "Value", with: "42"
        fill_in "Unit", with: "rpm"
        click_button "Create"
      end
      expect(page).to have_content("Device was successfully created")
      expect(page).to have_content("New Virtual Integer")
      device = Device.find_by(name: "New Virtual Integer")
      expect(device.device_type).to eq("Device::VirtualInteger")
      expect(device.value_integer).to eq(42)
      expect(device.unit).to eq("rpm")
    end

    scenario "creates a Virtual String device", js: true do
      visit devices_path
      click_link "Add Device"
      within "#ajax-modal" do
        fill_in "Name", with: "New Virtual String"
        select "Virtual String", from: "Type"
        expect(page).to have_no_field("Writable?")
        fill_in "Value", with: "Hello World"
        click_button "Create"
      end
      expect(page).to have_content("Device was successfully created")
      expect(page).to have_content("New Virtual String")
      device = Device.find_by(name: "New Virtual String")
      expect(device.device_type).to eq("Device::VirtualString")
      expect(device.value_string).to eq("Hello World")
    end
  end

  describe "creating devices for Modbus TCP board" do
    scenario "creates a Virtual Boolean device for Modbus TCP board", js: true do
      visit devices_path
      click_link "Add Device"
      within "#ajax-modal" do
        fill_in "Name", with: "Modbus Virtual Boolean"
        select "Modbus Board", from: "Board"
        wait_for_modal_reload
        select "Virtual Boolean", from: "Type"
        wait_for_modal_reload
        expect(page).to have_field("Writable?")
        fill_in "Holding Register", with: "100"
        fill_in "Value Scale", with: "10"
        select "uint16", from: "ModBus Data Type"
        click_button "Create"
      end
      expect(page).to have_content("Device was successfully created")
      expect(page).to have_content("Modbus Virtual Boolean")
      device = Device.find_by(name: "Modbus Virtual Boolean")
      expect(device.device_type).to eq("Device::VirtualBoolean")
      expect(device.board).to eq(modbus_board)
      expect(device.virtual_writable).to be false
      expect(device.holding_register_address).to eq(100)
      expect(device.scale).to eq(10)
      expect(device.modbus_data_type).to eq("uint16")
    end

    scenario "creates a Virtual Decimal device for Modbus TCP board", js: true do
      visit devices_path
      click_link "Add Device"
      within "#ajax-modal" do
        fill_in "Name", with: "Modbus Virtual Decimal"
        select "Modbus Board", from: "Board"
        wait_for_modal_reload
        select "Virtual Decimal", from: "Type"
        wait_for_modal_reload
        expect(page).to have_field("Writable?")
        fill_in "Holding Register", with: "101"
        fill_in "Value Scale", with: "10"
        select "int16", from: "ModBus Data Type"
        fill_in "Unit", with: "°C"
        click_button "Create"
      end
      expect(page).to have_content("Device was successfully created")
      expect(page).to have_content("Modbus Virtual Decimal")
      device = Device.find_by(name: "Modbus Virtual Decimal")
      expect(device.device_type).to eq("Device::VirtualDecimal")
      expect(device.board).to eq(modbus_board)
      expect(device.virtual_writable).to be false
      expect(device.holding_register_address).to eq(101)
      expect(device.scale).to eq(10)
      expect(device.modbus_data_type).to eq("int16")
      expect(device.unit).to eq("°C")
    end

    scenario "creates a Virtual Integer device for Modbus TCP board", js: true do
      visit devices_path
      click_link "Add Device"
      within "#ajax-modal" do
        fill_in "Name", with: "Modbus Virtual Integer"
        select "Modbus Board", from: "Board"
        wait_for_modal_reload
        select "Virtual Integer", from: "Type"
        wait_for_modal_reload
        expect(page).to have_field("Writable?")
        fill_in "Holding Register", with: "102"
        fill_in "Value Scale", with: "100"
        select "uint16", from: "ModBus Data Type"
        fill_in "Unit", with: "rpm"
        click_button "Create"
      end
      expect(page).to have_content("Device was successfully created")
      expect(page).to have_content("Modbus Virtual Integer")
      device = Device.find_by(name: "Modbus Virtual Integer")
      expect(device.device_type).to eq("Device::VirtualInteger")
      expect(device.board).to eq(modbus_board)
      expect(device.virtual_writable).to be false
      expect(device.holding_register_address).to eq(102)
      expect(device.scale).to eq(100)
      expect(device.modbus_data_type).to eq("uint16")
      expect(device.unit).to eq("rpm")
    end
  end

  describe "creating devices with compression" do
    scenario "creates a device with log compression", js: true do
      visit devices_path
      click_link "Add Device"
      within "#ajax-modal" do
        fill_in "Name", with: "Compressed Device"
        select "Arduino Board", from: "Board"
        wait_for_modal_reload
        select "Analog Input", from: "Type"
        wait_for_modal_reload
        fill_in "Pin/Address", with: "5"
        check "Log Enabled"
        wait_for_modal_reload
        select "Average Value", from: "Device Log Compression"
        wait_for_modal_reload
        select "5 minutes", from: "Timespan"
        fill_in "Backlog", with: "12"
        fill_in "Clear Logs After (days)", with: "7"
        click_button "Create"
      end
      expect(page).to have_content("Device was successfully created")
      expect(page).to have_content("Compressed Device")
      device = Device.find_by(name: "Compressed Device")
      expect(device.device_type).to eq("Device::AnalogInput")
      expect(device.compression_type).to eq("average")
      expect(device.compression_timespan).to eq("min5")
      expect(device.compression_backlog).to eq(12)
      expect(device.days_to_preserve_logs).to eq(7)
    end
  end

  describe "editing devices via modal" do
    scenario "edits an existing device", js: true do
      visit devices_path
      click_link "Edit", href: edit_device_path(switch_device)
      within "#ajax-modal" do
        fill_in "Name", with: "Updated Switch"
        click_button "Update"
      end
      expect(page).to have_content("Device was successfully updated")
      expect(page).to have_content("Updated Switch")
      switch_device.reload
      expect(switch_device.name).to eq("Updated Switch")
    end

    scenario "edits a device with Modbus attributes", js: true do
      modbus_device = create(:virtual_boolean, :modbus_writable, name: "Modbus Device", board: modbus_board)
      visit devices_path
      click_link "Edit", href: edit_device_path(modbus_device)
      within "#ajax-modal" do
        fill_in "Holding Register", with: "200"
        fill_in "Value Scale", with: "2"
        select "int16", from: "ModBus Data Type"
        click_button "Update"
      end
      expect(page).to have_content("Device was successfully updated")
      modbus_device.reload
      expect(modbus_device.holding_register_address).to eq(200)
      expect(modbus_device.scale).to eq(2)
      expect(modbus_device.modbus_data_type).to eq("int16")
    end
  end

  describe "removing devices" do
    scenario "removes a device", js: true do
      visit devices_path
      find("a[href='#{device_path(switch_device)}'][data-method='delete']").click
      within "#confirm-modal" do
        click_link "Confirm"
      end
      expect(page).to have_content("Device was successfully removed")
      expect(page).not_to have_content("Test Switch")
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

  describe "setting device values" do
    scenario "sets boolean device value via toggle buttons", js: true do
      visit devices_path
      Timecop.freeze(Time.parse("2025-01-01 12:00:00")) do
        within "[data-device-id='#{relay_device.id}']" do
          find(".toggle-off").click
          expect(page).to have_content("on")
          expect(page).to have_css(".toggle-on")
          expect(page).to have_content("1.1.2025 12:00:00")
        end
        relay_device.reload
      end
      expect(relay_device.value_boolean).to be true
      within "[data-device-id='#{relay_device.id}']" do
        find(".toggle-on").click
        expect(page).to have_content("off")
        expect(page).to have_css(".toggle-off")
      end
      relay_device.reload
      expect(relay_device.value_boolean).to be false
    end

    scenario "does not show toggle buttons for non-toggleable devices", js: true do
      visit devices_path
      within "table tbody tr:nth-child(1)" do
        expect(page).not_to have_css(".toggle-off")
        expect(page).not_to have_css(".toggle-on")
      end
    end
  end
end