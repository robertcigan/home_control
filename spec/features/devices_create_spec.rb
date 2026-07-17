require "rails_helper"

RSpec.feature "Devices creation", type: :feature do
  include_context "devices feature setup"

  describe "creating devices via form page" do
    scenario "creates a Switch device", js: true do
      visit devices_path
      click_link "Add Device"
      fill_in "Name", with: "New Switch"
      select_and_reload "Arduino Board", from: "Board"
      select_and_reload "Switch", from: "Type"
      expect(page).to have_field("Inverted")
      expect(page).to have_field("Pin/Address", visible: :visible)
      fill_in "Pin/Address", with: "4"
      check "Inverted"
      check "Log Enabled"
      fill_in "Clear Logs After (days)", with: "30"
      click_button "Create"
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
      fill_in "Name", with: "New Relay"
      select_and_reload "Arduino Board", from: "Board"
      expect_tom_select_selected("Board", selected: "Arduino Board")
      select_and_reload "Relay", from: "Type"
      expect_tom_select_selected("Type", selected: "Relay")
      expect(page).to have_field("Inverted")
      expect(page).to have_field("Pin/Address", visible: :visible)
      fill_in "Pin/Address", with: "5"
      check "Inverted"
      click_button "Create"
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
      fill_in "Name", with: "New Analog"
      select_and_reload "Arduino Board", from: "Board"
      select_and_reload "Analog Input", from: "Type"
      expect(page).to have_field("Pin/Address")
      fill_in "Pin/Address", with: "5"
      fill_in "Poll", with: "500"
      fill_in "Unit", with: "V"
      click_button "Create"
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
      fill_in "Name", with: "New Button"
      select_and_reload "Arduino Board", from: "Board"
      select_and_reload "Button", from: "Type"
      expect(page).to have_field("Inverted")
      expect(page).to have_field("Pin/Address")
      fill_in "Pin/Address", with: "5"
      check "Inverted"
      click_button "Create"
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
      fill_in "Name", with: "New PWM"
      select_and_reload "Arduino Board", from: "Board"
      select_and_reload "PWM output", from: "Type"
      expect(page).to have_field("Pin/Address")
      fill_in "Pin/Address", with: "5"
      fill_in "Value", with: "50"
      click_button "Create"
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
      fill_in "Name", with: "New Temp Sensor"
      select_and_reload "Arduino Board", from: "Board"
      expect_tom_select_selected("Board", selected: "Arduino Board")
      select_and_reload "DS18B20 Temperature Sensor", from: "Type"
      expect_tom_select_selected("Type", selected: "DS18B20 Temperature Sensor")
      expect(page).to have_field("Poll")
      expect(page).to have_field("Pin/Address")
      fill_in "Pin/Address", with: "5"
      expect(find_field("Pin/Address").value).to eq("5")
      fill_in "Unit", with: "°C"
      click_button "Create"
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
      fill_in "Name", with: "New Distance"
      select_and_reload "Arduino Board", from: "Board"
      select_and_reload "Distance", from: "Type"
      expect(page).to have_field("Poll")
      expect(page).to have_field("Pin/Address")
      fill_in "Pin/Address", with: "5"
      expect(find_field("Pin/Address").value).to eq("5")
      fill_in "Unit", with: "cm"
      click_button "Create"
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
      fill_in "Name", with: "New Curtain"
      select_and_reload "Arduino Board", from: "Board"
      select_and_reload "Blinds/Shutter/Curtain", from: "Type"
      expect(page).to have_field("Inverted")
      expect(page).to have_field("Pin/Address")
      fill_in "Pin/Address", with: "5"
      check "Inverted"
      click_button "Create"
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
      fill_in "Name", with: "New Sound"
      select_and_reload "Arduino Board", from: "Board"
      select_and_reload "Sound", from: "Type"
      expect(page).to have_field("Pin/Address")
      fill_in "Pin/Address", with: "5"
      click_button "Create"
      expect(page).to have_content("Device was successfully created")
      expect(page).to have_content("New Sound")
      device = Device.find_by(name: "New Sound")
      expect(device.device_type).to eq("Device::Sound")
      expect(device.pin).to eq(5)
    end

    scenario "creates a Board Test device", js: true do
      visit devices_path
      click_link "Add Device"
      fill_in "Name", with: "New Board Test"
      select_and_reload "Arduino Board", from: "Board"
      select_and_reload "Board Test", from: "Type"
      expect(page).to have_field("Pin/Address")
      fill_in "Pin/Address", with: "10"
      click_button "Create"
      expect(page).to have_content("Device was successfully created")
      expect(page).to have_content("New Board Test")
      device = Device.find_by(name: "New Board Test")
      expect(device.device_type).to eq("Device::BoardTest")
      expect(device.pin).to eq(10)
    end
  end
end
