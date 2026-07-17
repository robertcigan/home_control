require "rails_helper"

RSpec.feature "UI Patterns", type: :feature do
  let!(:board) { create(:board, name: "UI Board", ip: "192.168.1.50") }
  let!(:device) { create(:switch, name: "UI Switch", board: board, pin: 1) }
  let!(:panel) { create(:panel, name: "UI Panel") }

  describe "flash toasts" do
    scenario "shows success toast after create", js: true do
      visit boards_path
      click_link "Add Board"
      fill_in "Name", with: "Toast Board"
      fill_in "IP", with: "192.168.1.99"
      select_tom "Arduino Mega (8bit)", from: "Type"
      fill_in "Clear Logs After (days)", with: "30"
      click_button "Create"
      expect(page).to have_content("Board was successfully created")
    end

    scenario "shows validation errors on failed create", js: true do
      visit boards_path
      click_link "Add Board"
      fill_in "Name", with: ""
      click_button "Create"
      expect(page).to have_content("can't be blank")
    end
  end

  describe "confirmation dialog" do
    scenario "cancels delete and keeps the record", js: true do
      visit devices_path
      expect(page).to have_content("UI Switch")
      dismiss_confirm do
        find("a[href='#{device_path(device)}'][data-turbo-method='delete']").click
      end
      expect(page).to have_content("UI Switch")
      expect(Device.exists?(device.id)).to be true
    end

    scenario "confirms delete and removes the record", js: true do
      visit devices_path
      accept_confirm do
        find("a[href='#{device_path(device)}'][data-turbo-method='delete']").click
      end
      expect(page).to have_content("Device was successfully removed")
      expect(page).not_to have_content("UI Switch")
    end

    scenario "keeps layout editor after dismissing delete confirm", js: true do
      widget = create(:widget, :type_text_value, panel: panel, device: device)
      visit panel_widgets_path(panel)
      within first(".grid-stack-item") do
        find(".grid-stack-item-content").hover
        dismiss_confirm do
          find("a[href='#{panel_widget_path(panel, widget)}'][data-turbo-method='delete']").click
        end
      end
      expect(page).to have_css(".grid-stack-edit")
      expect(Widget.exists?(widget.id)).to be true
    end
  end
end
