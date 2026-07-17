RSpec.shared_examples "cable updates dom" do |visit_path:, model:, update_attrs:, within_selector:, assertion:|
  scenario "updates DOM when #{model.class.name} changes over cable", js: true do
    visit visit_path
    within within_selector do
      assertion.call(page, :before)
    end
    model.update!(update_attrs)
    within within_selector do
      assertion.call(page, :after)
    end
  end
end
