require "rails_helper"

RSpec.feature "Widget Layout", type: :feature do
  let!(:arduino_board) { create(:board, name: "Arduino Board", ip: "192.168.1.10") }
  let!(:relay_device) { create(:relay, name: "Relay A", board: arduino_board, pin: 2) }
  let!(:panel) { create(:panel, name: "Layout Panel") }
  let!(:widget) do
    create(:widget, :type_switch, panel: panel, device: relay_device, x: 1, y: 2, w: 3, h: 4, show_label: true)
  end

  scenario "renders widgets at stored grid positions", js: true do
    visit panel_widgets_path(panel)
    expect(page).to have_css(".grid-stack-item[gs-x='1'][gs-y='2'][gs-w='3'][gs-h='4']")
  end

  scenario "reloads dashboard when widget position changes over cable", js: true do
    visit panel_path(panel)
    expect(page).to have_css(".grid-stack-item[gs-w='3'][gs-h='4']")
    widget.update!(w: 2, h: 2)
    panel.touch
    expect(page).to have_css(".grid-stack-item[gs-w='2'][gs-h='2']")
  end

  scenario "persists new grid coordinates from layout editor", js: true do
    visit panel_widgets_path(panel)
    page.execute_script(<<~JS)
      var item = document.querySelector('.grid-stack-item');
      item.setAttribute('gs-x', '2');
      item.setAttribute('gs-y', '3');
      item.setAttribute('gs-w', '4');
      item.setAttribute('gs-h', '2');
      $(item).trigger('widget:update');
    JS
    wait_until { widget.reload.x == 2 }
    expect(widget).to have_attributes(x: 2, y: 3, w: 4, h: 2)
  end
end
