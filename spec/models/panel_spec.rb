require "rails_helper"

RSpec.describe Panel, type: :model do
  let(:panel) { create(:panel) }

  describe "validations" do
    it { should validate_presence_of(:name) }
  end

  describe "associations" do
    it { should have_many(:widgets).dependent(:destroy) }
  end

  describe "#to_s" do
    it "returns the panel name" do
      expect(panel.to_s).to eq(panel.name)
    end
  end

  describe "attributes" do
    it "has default grid size values" do
      expect(panel.row).to eq(12)
      expect(panel.column).to eq(12)
    end

    it "has public_access attribute" do
      expect(panel).to respond_to(:public_access)
      expect(panel).to respond_to(:public_access=)
    end
  end
end