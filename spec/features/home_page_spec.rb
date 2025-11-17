require "rails_helper"

RSpec.feature "Home page", type: :feature do
  scenario "visits the home page", js: true do
    visit root_path
    expect(page).to have_content("Home Control")
    expect(page).to have_content("Panels")
  end
end