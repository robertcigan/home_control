require "rails_helper"

RSpec.feature "Programs", type: :feature do
  let!(:arduino_board) { create(:board, name: "Arduino Board", ip: "192.168.1.10") }
  let!(:relay_device)   { create(:relay, name: "Relay A", board: arduino_board, pin: 2) }
  let!(:virtual_bool)   { create(:virtual_boolean, name: "Virtual A", board: arduino_board) }
  let!(:program)        { create(:program, name: "Temp Program", code: "log_info('ok')") }

  describe "index page" do
    scenario "filters programs by name", js: true do
      create(:program, name: "Alpha")
      create(:program, :repeated, name: "Repeater")

      visit programs_path
      expect(page).to have_content("Programs")
      fill_in "Search by Name", with: "Alpha"
      expect(page).to have_content("Alpha")
      expect(page).to have_no_content("Repeater")
    end

    scenario "filters programs by type", js: true do
      create(:program, name: "Alpha")
      create(:program, :repeated, name: "Repeater")

      visit programs_path
      select_and_submit "Repeated", from: "q_program_type_eq"
      expect(page).to have_content("Repeater")
      expect(page).to have_no_content("Alpha")
    end

    scenario "shows pagination controls", js: true do
      25.times { |i| create(:program, name: "Program #{i}") }
      visit programs_path
      expect(page).to have_selector(".page-pagination")
      expect(page).to have_css("table tbody tr", count: 20)
      within ".page-pagination" do
        click_link "2"
      end
      expect(page).to have_css("table tbody tr", count: 6)
    end

    scenario "sorts by name", js: true do
      create(:program, name: "Beta")
      create(:program, name: "Alpha")
      visit programs_path
      click_link "Name"
      expect(page).to have_selector("table")
    end
  end

  describe "create/edit via form page" do
    scenario "creates a default program with devices", js: true do
      programs = Program.count
      visit programs_path
      click_link "Add Program"
      fill_in "Name", with: "New Program"
      select_and_reload "Input activated", from: "Program type"
      expect(page).to have_css('.cm-editor')
      code = "log_info('hello')\n"
      page.execute_script("var el=document.querySelector('.cm-editor'); el.editorView.dispatch({changes:{from:0,to:el.editorView.state.doc.length,insert:#{code.to_json}}});")
      click_link "Add"
      within "#programs_devices" do
        select_tom "Relay A"
      end
      wait_for_form_reload
      within "#programs_devices" do
        fill_in "Variable Name", with: "relay"
      end
      wait_for_form_reload
      within "#programs_devices" do
        check "Trigger"
      end
      click_button "Create"
      expect(page).to have_content("Program was successfully created")
      expect(page).to have_content("New Program")
      expect(Program.count).to eq(programs + 1)
    end

    scenario "shows validation errors on failure", js: true do
      visit programs_path
      click_link "Add Program"
      fill_in "Name", with: ""
      click_button "Create"
      expect(page).to have_content("can't be blank")
    end
  end

  describe "editing programs via form page" do
    scenario "edits an existing program", js: true do
      visit programs_path
      click_link "Edit", href: edit_program_path(program)
      fill_in "Name", with: "Updated Program"
      click_button "Update"
      expect(page).to have_content("Program was successfully updated")
      expect(page).to have_content("Updated Program")
    end
  end

  describe "show page interactions" do
    scenario "enables/disables and runs a program (mocked)", js: true do
      allow_any_instance_of(Program).to receive(:run).and_wrap_original do |m, *args|
        subject = m.receiver
        subject.update(output: "mocked run", last_run: Time.current, runtime: 5)
      end

      visit program_path(program)
      find(".toggle-off").click
      expect(page).to have_content("turned on")
      accept_confirm do
        find(".fa-play").find(:xpath, "..").click
      end
      expect(page).to have_content("successfully run")
      expect(page).to have_content("mocked run")
      find(".toggle-on").click
      expect(page).to have_content("turned off")
    end

    scenario "run failure shows error", js: true do
      allow_any_instance_of(Program).to receive(:run).and_wrap_original do |m, *args|
        subject = m.receiver
        subject.update(output: "boom", last_error_at: Time.current, last_error_message: "Kaboom", last_run: Time.current, runtime: 1)
      end

      visit program_path(program)
      accept_confirm do
        find(".fa-play").find(:xpath, "..").click
      end
      expect(page).to have_content("Program #{program.name} successfully run")
      expect(page).to have_content("boom")
      visit program_path(program)
      expect(page).to have_content("boom")
      expect(page).to have_content("Kaboom")
    end
  end

  describe "duplicate", js: true do
    scenario "copies an existing program via form page" do
      programs = Program.count
      visit program_path(program)
      click_link "Copy program"
      expect(page).to have_field("Name", with: program.name)
      fill_in "Name", with: "Copied Program"
      expect(page).to have_field("Name", with: "Copied Program")
      click_button "Create"
      expect(page).to have_content("Program was successfully created")
      expect(Program.count).to eq(programs + 1)
      copied_program = Program.order(:id).last
      expect(copied_program.name).to eq("Copied Program")
      expect(copied_program.code).to eq(program.code)
    end
  end

  describe "removing programs" do
    scenario "removes a program", js: true do
      programs = Program.count
      visit programs_path
      accept_confirm do
        find("a[href='#{program_path(program)}'][data-turbo-method='delete']").click
      end
      expect(page).to have_content("Program was successfully removed")
      expect(Program.count).to eq(programs - 1)
      expect(page).not_to have_content(program.name)
    end
  end

  describe "ActionCable realtime updates" do
    scenario "shows last run/time updates pushed over cable", js: true do
      visit program_path(program)
      card = find(".card.program")
      wait_for_action_cable

      last_run_at = Time.zone.parse("2025-06-15 12:00:00")
      program.update!(last_run: last_run_at, runtime: 7)
      formatted = I18n.l(program.reload.last_run, format: :custom)

      expect(card.find(".last-run")).to have_content(formatted, wait: 10)
      expect(card.find(".runtime")).to have_content("7", wait: 10)
    end
  end

  describe "reload form round-trip" do
    scenario "preserves entered values when program type changes without creating a record", js: true do
      visit programs_path
      click_link "Add Program"
      fill_in "Name", with: "Reload Program"
      select_and_reload "Repeated", from: "Program type"
      expect(page).to have_field("Name", with: "Reload Program")
      expect(Program.find_by(name: "Reload Program")).to be_nil
    end
  end
end
