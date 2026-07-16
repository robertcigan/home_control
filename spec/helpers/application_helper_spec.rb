require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#page_title" do
    it "sets content_for :title and returns the title string" do
      expect(helper.page_title("Boards")).to eq("Boards")
      expect(helper.content_for(:title)).to eq("Boards")
    end
  end
end
