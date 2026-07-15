require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#show_flash" do
    it "returns success flash script for notice" do
      helper.flash[:notice] = "Saved"
      expect(helper.show_flash).to include('HomeControl.Layout.showFlash("Saved", \'success\')')
    end

    it "returns alert flash script for alert" do
      helper.flash[:alert] = "Failed"
      expect(helper.show_flash).to include('HomeControl.Layout.showFlash("Failed", \'alert\')')
    end

    it "returns nil when flash is empty" do
      expect(helper.show_flash).to be_nil
    end
  end

  describe "#refresh_list_by_script" do
    it "includes form selector and pagination guard" do
      script = helper.refresh_list_by_script("#devices_search_form")
      expect(script).to include("#devices_search_form")
      expect(script).to include(".pagination")
      expect(script).to include("getScript")
    end
  end
end
