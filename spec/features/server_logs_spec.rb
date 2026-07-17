require "rails_helper"

RSpec.feature "Server logs", type: :feature do
  scenario "lists log files on index page", js: true do
    visit logs_path
    expect(page).to have_content(".log")
  end
end