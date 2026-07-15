require "rails_helper"

RSpec.feature "Devices management", type: :feature do
  include_context "devices feature setup"

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

  describe "ActionCable realtime updates" do
    scenario "updates indication on index when device value changes", js: true do
      relay_device.update!(value_boolean: false)
      visit devices_path
      row = find("tr.device", text: "Test Arduino Relay")
      expect(row.find(".indication")).to have_content("off")
      relay_device.update!(value_boolean: true)
      expect(row.find(".indication")).to have_content("on")
    end

    scenario "updates indication on show page when device value changes", js: true do
      relay_device.update!(value_boolean: false)
      visit device_path(relay_device)
      card = find(".card.device")
      expect(card.find(".indication")).to have_content("off")
      relay_device.update!(value_boolean: true)
      expect(card.find(".indication")).to have_content("on")
    end

    scenario "updates toggle buttons after value change over cable", js: true do
      relay_device.update!(value_boolean: false)
      visit devices_path
      row = find("tr.device", text: "Test Arduino Relay")
      relay_device.update!(value_boolean: true)
      within row do
        expect(page).to have_content("on")
        expect(page).to have_css(".toggle-on", visible: :visible)
      end
    end
  end
end
