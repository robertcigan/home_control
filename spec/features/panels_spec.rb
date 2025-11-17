require "rails_helper"

RSpec.feature "Panels", type: :feature do
  let!(:arduino_board) { create(:board, name: "Arduino Board", ip: "192.168.1.10") }
  let!(:relay_device)   { create(:relay, name: "Relay A", board: arduino_board, pin: 2) }
  let!(:program)        { create(:program, name: "Helper Program") }
  let!(:panel)          { create(:panel, name: "Main Panel") }

  describe "index page" do
    scenario "filters panels by name", js: true do
      create(:panel, name: "Office")
      visit panels_path
      expect(page).to have_content("Panels")
      fill_in "Search by Name", with: "Office"
      expect(page).to have_content("Office")
      expect(page).to have_no_content("Main Panel")
    end

    scenario "shows pagination controls", js: true do
      25.times { |i| create(:panel, name: "Panel #{i}") }
      visit panels_path
      expect(page).to have_selector(".page-pagination")
      expect(page).to have_css("table tbody tr", count: 20)
      within ".page-pagination" do
        click_link "2"
      end
      expect(page).to have_css("table tbody tr", count: 6)
    end
  end

  describe "creating panels via modal" do
    scenario "creates a panel with one widget", js: true do
      visit panels_path
      click_link "Add Panel"
      within "#ajax-modal" do
        fill_in "Name", with: "New Panel"
        check "Public Access"
        click_link "Add"
        within "#widgets" do
          first("select").select "Switch"
          wait_for_modal_reload
          select "Relay A", from: "Device"
        end
        click_button "Create"
      end
      expect(page).to have_content("Panel was successfully created")
      expect(page).to have_content("New Panel")
    end

    scenario "shows validation errors on failure", js: true do
      visit panels_path
      click_link "Add Panel"
      within "#ajax-modal" do
        fill_in "Name", with: ""
        click_button "Create"
        expect(page).to have_content("can't be blank")
      end
    end
  end

  describe "editing panels via modal" do
    scenario "edits a panel name", js: true do
      visit panels_path
      within "#panels table tbody tr:nth-child(1)" do
        click_link "Edit"
      end
      within "#ajax-modal" do
        first("a.remove_fields").click
        wait_for_modal_reload
        fill_in "Name", with: "Changed name"
        click_button "Update"
      end
      expect(page).to have_content("Panel was successfully updated")
      within "#panels table tbody tr:nth-child(1)" do
        expect(page).to have_content("Changed name")
      end
    end
  end

  describe "panel show and live updates" do
    scenario "displays widgets and reacts to realtime updates", js: true do
      device = create(:switch, name: "Switch device", value_boolean: false)
      create(:widget, :type_switch, panel: panel, device: device, x: 0, y: 0, w: 2, h: 4, show_label: true)
      visit panel_path(panel)
      expect(page).to have_content(panel.name)
      expect(page).to have_css(".toggle-off", visible: :visible)
      expect(page).to have_css(".toggle-on", visible: :hidden)
      device.update(value_boolean: true)
      expect(page).to have_css(".toggle-off", visible: :hidden)
      expect(page).to have_css(".toggle-on", visible: :visible)
    end

    scenario "reloads panel when widget changes (push)", js: true do
      widget = create(:widget, :type_switch, panel: panel, device: relay_device, x: 0, y: 0, w: 2, h: 2, show_label: true)
      visit panel_path(panel)
      expect(page).to have_css(".grid-stack-item[gs-w='2'][gs-h='2']")
      widget.update(w: 1, h: 1)
      panel.touch
      expect(page).to have_css(".grid-stack-item[gs-w='1'][gs-h='1']")
    end
  end

  describe "widgets in panel" do
    scenario "adds a widget via modal", js: true do
      visit panels_path
      click_link "Add Panel"
      within "#ajax-modal" do
        fill_in "Name", with: "With Widget"
        click_link "Add"
        wait_for_modal_reload
        within "#widgets" do
          first("select").select "Text Value"
          select "Relay A", from: "Device"
          wait_for_modal_reload
        end
        click_button "Create"
      end
      expect(page).to have_content("Panel was successfully created")
      expect(Panel.exists?(name: "With Widget")).to be true
    end

    scenario "edits a widget via modal", js: true do
      existing_panel = create(:panel, name: "Edit Panel")
      widget = create(:widget, panel: existing_panel, widget_type: "text_value", device: relay_device)
      visit panels_path
      click_link "Layout", href: panel_widgets_path(existing_panel)
      within first(".grid-stack-item") do
        find(".grid-stack-item-content").hover
        click_link "Edit", href: edit_panel_widget_path(existing_panel, existing_panel.widgets.first)
      end
      within "#ajax-modal" do
        fill_in "Name", with: "Status"
        click_button "Update"
      end
      expect(page).to have_content("Widget was successfully updated")
      expect { widget.reload }.to change { widget.name }.to("Status")
    end

    scenario "removes a widget", js: true do
      existing_panel = create(:panel, name: "Removable Panel")
      widget = create(:widget, panel: existing_panel, widget_type: "text_value", device: relay_device)
      visit panels_path
      click_link "Layout", href: panel_widgets_path(existing_panel)
      within first(".grid-stack-item") do
        find(".grid-stack-item-content").hover
        find("a[href='#{panel_widget_path(existing_panel, existing_panel.widgets.first)}'][data-method='delete']").click
      end
      within "#confirm-modal" do
        click_link "Confirm"
      end
      expect(page).to have_no_css(".grid-stack-item")
      expect { widget.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end


