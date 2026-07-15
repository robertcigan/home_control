require "rails_helper"

RSpec.feature "Devices virtual and Modbus creation", type: :feature do
  include_context "devices feature setup"

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

  describe "reload form round-trip" do
    scenario "preserves entered values when device type changes without creating a record", js: true do
      visit devices_path
      click_link "Add Device"
      within "#ajax-modal" do
        fill_in "Name", with: "Reload Test Device"
        select "Arduino Board", from: "Board"
        select "Relay", from: "Type"
        wait_for_modal_reload
        fill_in "Pin/Address", with: "7"
        select "Switch", from: "Type"
        wait_for_modal_reload
        expect(page).to have_field("Name", with: "Reload Test Device")
        expect(page).to have_field("Pin/Address", with: "7")
      end
      expect(Device.find_by(name: "Reload Test Device")).to be_nil
    end
  end
end
