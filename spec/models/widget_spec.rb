require "rails_helper"

RSpec.describe Widget, type: :model do
  let(:widget) { create(:widget, :type_button) }

  describe "validations" do
  end

  describe "associations" do
    it { should belong_to(:panel) }
    it { should belong_to(:device).optional }
    it { should belong_to(:program).optional }
  end

  describe "#to_s" do
    it "returns the widget name" do
      expect(widget.to_s).to eq(widget.name)
    end
  end
end