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
      select "Repeated", from: "q_program_type_eq"
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

  describe "create/edit via modal" do
    scenario "creates a default program with devices", js: true do
      programs = Program.count
      visit programs_path
      click_link "Add Program"
      within "#ajax-modal" do
        fill_in "Name", with: "New Program"
        select "Input activated", from: "Program type"
        wait_for_modal_reload
        expect(page).to have_css('#ajax-modal .CodeMirror')
        code = "log_info('hello')\n"
        page.execute_script("var cm=document.querySelector('#ajax-modal .CodeMirror').CodeMirror; cm.setValue(#{"log_info('hello')\n".to_json}); cm.save();")
        click_link "Add"
        within "#programs_devices" do
          first("select").select "Relay A"
          wait_for_modal_reload
          fill_in "Variable Name", with: "relay"
          wait_for_modal_reload
          check "Trigger"
        end
        click_button "Create"
      end
      expect(page).to have_content("Program was successfully created")
      expect(page).to have_content("New Program")
      expect(Program.count).to eq(programs + 1)
    end

    scenario "shows validation errors on failure", js: true do
      visit programs_path
      click_link "Add Program"
      within "#ajax-modal" do
        fill_in "Name", with: ""
        click_button "Create"
        expect(page).to have_content("can't be blank")
      end
    end
  end

  describe "editing programs via modal" do
    scenario "edits an existing program", js: true do
      visit programs_path
      click_link "Edit", href: edit_program_path(program)
      within "#ajax-modal" do
        fill_in "Name", with: "Updated Program"
        click_button "Update"
      end
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
      find(".fa-play").find(:xpath, "..").click
      within "#confirm-modal" do
        click_link "Confirm"
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
      find(".fa-play").find(:xpath, "..").click
      within "#confirm-modal" do
        click_link "Confirm"
      end
      expect(page).to have_content("Program #{program.name} successfully run")
      expect(page).to have_content("boom")
      visit program_path(program)
      expect(page).to have_content("boom")
      expect(page).to have_content("Kaboom")
    end
  end

  describe "duplicate", js: true do
    scenario "copies an existing program via modal" do
      programs = Program.count
      visit program_path(program)
      click_link "Copy program"
      within "#ajax-modal" do
        expect(page).to have_field("Name", with: program.name)
        fill_in "Name", with: "Copied Program"
        expect(page).to have_field("Name", with: "Copied Program")
        click_button "Create"
      end
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
      find("a[href='#{program_path(program)}'][data-method='delete']").click
      within "#confirm-modal" do
        click_link "Confirm"
      end
      expect(page).to have_content("Program was successfully removed")
      expect(Program.count).to eq(programs - 1)
      expect(page).not_to have_content(program.name)
    end
  end

  describe "ActionCable realtime updates" do
    scenario "shows last run/time updates pushed over cable", js: true do
      visit program_path(program)
      program.update(last_run: Time.current - 1.minute, runtime: 7)
      formatted = I18n.l(program.reload.last_run, format: :custom)
      expect(page).to have_content(formatted)
      expect(page).to have_css(".last-run", text: formatted)
    end
  end
end


