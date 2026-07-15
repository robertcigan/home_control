require "rails_helper"

RSpec.feature "Server logs", type: :feature do
  scenario "lists log files on index page", js: true do
    visit logs_path
    expect(page).to have_content(".log")
  end

  scenario "shows tail output for a log file", js: true do
    log_file = Rails.root.join("log", "test.log")
    File.write(log_file, "sample log line\n")

    visit log_path(file: "test.log")
    expect(page).to have_content("sample log line")
  end
end
