require "rails_helper"

RSpec.describe "Backups", type: :request do
  describe "GET /backup/download" do
    it "returns bad request for unknown format" do
      get download_backup_path(format: "invalid")
      expect(response).to have_http_status(:bad_request)
    end

    it "returns sql backup when pg_dump succeeds" do
      status = instance_double(Process::Status, success?: true)
      allow(Process).to receive(:last_status).and_return(status)
      allow_any_instance_of(BackupsController).to receive(:`).and_return("SQL DUMP")

      get download_backup_path(format: "sql")
      expect(response).to have_http_status(:ok)
      expect(response.header["Content-Disposition"]).to include("attachment")
      expect(response.body).to eq("SQL DUMP")
    end

    it "redirects with alert when backup raises an exception" do
      allow_any_instance_of(BackupsController).to receive(:`).and_raise(StandardError.new("shell failed"))

      get download_backup_path(format: "sql")
      expect(response).to redirect_to(backup_path)
      expect(flash[:alert]).to include("shell failed")
    end
  end
end
