require "rails_helper"

RSpec.describe "Board logs chart JSON", type: :request do
  let!(:board) { create(:board, :with_wifi, name: "Chart Board", ip: "192.168.1.55", connected_at: Time.current) }
  let(:frozen_time) { Time.zone.parse("2025-06-15 12:30:00") }

  before do
    create(:board_log, board: board, connected: true, signal_strength: 70,
      created_at: frozen_time.beginning_of_day + 3.hours)
    create(:board_log, board: board, connected: false, signal_strength: nil,
      created_at: frozen_time.beginning_of_day + 5.hours)
    create(:board_log, board: board, connected: true, signal_strength: 40,
      created_at: frozen_time.beginning_of_day - 1.hour)
    create(:board_log, board: board, connected: true, signal_strength: 90,
      created_at: frozen_time.end_of_day + 2.hours)
  end

  it "returns connection and signal strength series" do
    Timecop.freeze(frozen_time) do
      get chart_board_board_logs_path(board, format: :json, timespan: "day")
      data = JSON.parse(response.body)
      expect(data.size).to eq(2)
      expect(data.map { |series| series["name"] }).to contain_exactly("Connection", "Signal Strength")
      connection = data.find { |series| series["name"] == "Connection" }
      signal = data.find { |series| series["name"] == "Signal Strength" }
      expect(connection["data"]).to be_an(Array)
      expect(signal["data"]).to be_an(Array)
      expect(connection["data"].map(&:last)).to include(1, 0)
      expect(signal["data"].map(&:last)).to include(0.7)
    end
  end

  it "pads values before min and after max" do
    Timecop.freeze(frozen_time) do
      min = frozen_time.beginning_of_day
      max = frozen_time.end_of_day
      get chart_board_board_logs_path(board, format: :json, timespan: "day", min: min, max: max)
      data = JSON.parse(response.body)
      connection = data.find { |series| series["name"] == "Connection" }
      signal = data.find { |series| series["name"] == "Signal Strength" }
      expect(connection["data"].first.last).to eq(1)
      expect(connection["data"].last.last).to eq(1)
      expect(signal["data"].first.last).to eq(0.4)
      expect(signal["data"].last.last).to eq(0.9)
    end
  end
end
