require "rails_helper"

RSpec.describe LogsController, type: :controller do
  describe "#files" do
    it "only includes log files from the log directory" do
      files = described_class.new.send(:files)
      expect(files).not_to include("../../etc/passwd")
      expect(files).to all(end_with(".log"))
    end
  end
end
