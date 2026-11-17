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

  scenario "fits widget fonts on first load in layout editor", js: true do
    visit panel_widgets_path(panel)

    wait_until do
      page.evaluate_script(<<~JS)
        (function() {
          var label = document.querySelector(".widget-switch .resizable-font-size");
          return !!label && label.style.fontSize !== "" && parseFloat(getComputedStyle(label).fontSize) > 20;
        })()
      JS
    end

    duration = page.evaluate_script("getComputedStyle(document.querySelector('.grid-stack-item')).transitionDuration")
    expect(duration).to eq("0s")
  end

  scenario "stretches layout editor grid to the bottom of the viewport", js: true do
    visit panel_widgets_path(panel)
    expect(page).to have_css(".grid-stack-item")

    gap = page.evaluate_script(<<~JS)
      (function() {
        var grid = document.querySelector(".grid-stack-edit");
        var bottomPadding = parseFloat(getComputedStyle(document.body).paddingBottom);
        return window.innerHeight - bottomPadding - grid.getBoundingClientRect().bottom;
      })()
    JS

    # cell height is floored to whole pixels, so up to one pixel per row may remain
    expect(gap).to be_between(0, panel.row)
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
      item.dispatchEvent(new CustomEvent('widget:update'));
    JS
    wait_until { widget.reload.x == 2 }
    expect(widget).to have_attributes(x: 2, y: 3, w: 4, h: 2)
  end

  describe "widget without a stored position on a full panel" do
    let!(:full_panel) { create(:panel, name: "Full Panel", public_access: true, column: 3, row: 2) }
    # Created first, so the database returns it before the positioned widgets
    let!(:unplaced) do
      create(:widget, :type_switch, panel: full_panel, device: relay_device, name: "Unplaced").tap do |widget|
        widget.update_columns(x: nil, y: nil, w: nil, h: nil)
      end
    end
    let!(:placed) do
      [[0, 0], [1, 0], [2, 0], [0, 1], [1, 1]].map do |x, y|
        create(:widget, :type_switch, panel: full_panel, device: relay_device, x: x, y: y, w: 1, h: 1, name: "Placed #{x}-#{y}")
      end
    end

    def grid_positions
      page.evaluate_script(<<~JS)
        Array.from(document.querySelectorAll(".grid-stack-item")).map(function(el) {
          var node = el.gridstackNode;
          return [el.getAttribute("gs-id"), node.x, node.y, node.w, node.h];
        })
      JS
    end

    def expect_layout_kept
      expect(page).to have_css(".grid-stack-item", count: 6)
      expected = placed.map { |widget| [widget.id.to_s, widget.x, widget.y, 1, 1] }
      expected << [unplaced.id.to_s, 2, 1, 1, 1]
      expect(grid_positions).to match_array(expected)
    end

    scenario "keeps the other widgets in place on the panel", js: true do
      visit panel_path(full_panel)
      expect_layout_kept
    end

    scenario "keeps the other widgets in place in the layout editor", js: true do
      visit panel_widgets_path(full_panel)
      expect_layout_kept
    end
  end
end
