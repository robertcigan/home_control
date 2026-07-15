require "rails_helper"

RSpec.feature "Panels public access", type: :feature do
  let!(:arduino_board) { create(:board, name: "Arduino Board", ip: "192.168.1.10") }
  let!(:relay_device) { create(:relay, name: "Relay A", board: arduino_board, pin: 2, value_boolean: false) }
  let!(:program) { create(:program, name: "Panel Program", code: "log_info('run')") }
  let!(:public_panel) { create(:panel, name: "Public Panel", public_access: true) }
  let!(:private_panel) { create(:panel, name: "Private Panel", public_access: false) }

  describe "panel dashboard" do
    scenario "renders public panel without application navbar", js: true do
      create(:widget, :type_switch, panel: public_panel, device: relay_device, show_label: true)
      visit panel_path(public_panel)
      expect(page).to have_css(".grid-stack")
      expect(page).not_to have_link("Boards")
    end

    scenario "renders private panel with application navbar when not authenticated", js: true do
      create(:widget, :type_switch, panel: private_panel, device: relay_device, show_label: true)
      visit panel_path(private_panel)
      expect(page).to have_link("Boards")
    end
  end

  describe "widget interactions" do
    scenario "allows switch toggle on public panel", js: true do
      create(:widget, :type_switch, panel: public_panel, device: relay_device, show_label: true)
      visit panel_path(public_panel)
      find(".widget-switch a.toggle-off").click
      expect(page).to have_css(".toggle-on", visible: :visible, wait: 10)
      expect(relay_device.reload.value_boolean).to be true
    end

    scenario "blocks switch toggle on private panel without authentication", js: true do
      create(:widget, :type_switch, panel: private_panel, device: relay_device, show_label: true)
      visit panel_path(private_panel)
      find(".widget-switch a.toggle-off").trigger("click")
      expect(page).to have_css(".toggle-off", visible: :visible, wait: 10)
      expect(relay_device.reload.value_boolean).to be false
    end

    scenario "runs program button on public panel without flash", js: true do
      create(:widget, :type_button, panel: public_panel, program: program, show_label: true)
      visit panel_path(public_panel)
      find(".widget-button a").click
      expect(program.reload.last_run).not_to be_nil
      expect(page).not_to have_content("Program was successfully")
    end

    scenario "blocks program button on private panel without authentication", js: true do
      create(:widget, :type_button, panel: private_panel, program: program, show_label: true)
      visit panel_path(private_panel)
      find(".widget-button a").trigger("click")
      expect(program.reload.last_run).to be_nil
    end
  end
end
