require "rails_helper"

RSpec.describe BoardLog, type: :model do
  describe "validations" do
    it { should belong_to(:board) }
  end

  describe ".recent" do
    let!(:board) { create(:board) }
    let!(:old_log) { create(:board_log, board: board, created_at: 2.days.ago) }
    let!(:recent_log) { create(:board_log, board: board, created_at: 1.hour.ago) }
    let!(:newest_log) { create(:board_log, board: board, created_at: 1.minute.ago) }

    it "returns the 20 most recent logs ordered by id DESC" do
      recent_logs = BoardLog.recent
      expect(recent_logs.count).to be <= 20
      expect(recent_logs.first.id).to eq(newest_log.id)
      expect(recent_logs.last.id).to eq(old_log.id)
    end
  end

  describe "#indication" do
    it "returns connected when connected" do
      board_log = create(:board_log, connected: true)
      expect(board_log.indication).to eq("connected")
    end

    it "returns disconnected when disconnected" do
      board_log = create(:board_log, connected: false)
      expect(board_log.indication).to eq("disconnected")
    end
  end

  describe "#chart_data_status" do
    it "returns array with timestamp and status value when connected" do
      board_log = create(:board_log, connected: true, created_at: Time.parse("2023-01-01 12:00:00"))
      expected_data = ["2023-01-01 12:00:00 +0100", 1]
      expect(board_log.chart_data_status).to eq(expected_data)
    end

    it "returns array with timestamp and 0 status when disconnected" do
      board_log = create(:board_log, connected: false, created_at: Time.parse("2023-01-01 12:00:00"))
      expected_data = ["2023-01-01 12:00:00 +0100", 0]
      expect(board_log.chart_data_status).to eq(expected_data)
    end
  end

  describe "#chart_data_ssid" do
    it "returns array with timestamp and ssid when ssid is present" do
      board_log = create(:board_log, ssid: "TestWiFi", created_at: Time.parse("2023-01-01 12:00:00"))
      expected_data = ["2023-01-01 12:00:00 +0100", "TestWiFi"]
      expect(board_log.chart_data_ssid).to eq(expected_data)
    end

    it "returns array with timestamp and nil ssid when ssid is nil" do
      board_log = create(:board_log, ssid: nil, created_at: Time.parse("2023-01-01 12:00:00"))
      expected_data = ["2023-01-01 12:00:00 +0100", nil]
      expect(board_log.chart_data_ssid).to eq(expected_data)
    end
  end

  describe "#chart_data_signal_strength" do
    it "returns array with timestamp and normalized signal strength when signal_strength is present" do
      board_log = create(:board_log, signal_strength: 75, created_at: Time.parse("2023-01-01 12:00:00"))
      expected_data = ["2023-01-01 12:00:00 +0100", 0.75]
      expect(board_log.chart_data_signal_strength).to eq(expected_data)
    end

    it "returns array with timestamp and nil signal strength when signal_strength is nil" do
      board_log = create(:board_log, signal_strength: nil, created_at: Time.parse("2023-01-01 12:00:00"))
      expected_data = ["2023-01-01 12:00:00 +0100", nil]
      expect(board_log.chart_data_signal_strength).to eq(expected_data)
    end

    it "returns array with timestamp and 0.0 signal strength when signal_strength is 0" do
      board_log = create(:board_log, signal_strength: 0, created_at: Time.parse("2023-01-01 12:00:00"))
      expected_data = ["2023-01-01 12:00:00 +0100", 0.0]
      expect(board_log.chart_data_signal_strength).to eq(expected_data)
    end

    it "returns array with timestamp and 1.0 signal strength when signal_strength is 100" do
      board_log = create(:board_log, signal_strength: 100, created_at: Time.parse("2023-01-01 12:00:00"))
      expected_data = ["2023-01-01 12:00:00 +0100", 1.0]
      expect(board_log.chart_data_signal_strength).to eq(expected_data)
    end
  end

  describe "ransackable attributes" do
    it "includes authorizable ransackable attributes" do
      expect(BoardLog.ransackable_attributes).to eq(BoardLog.authorizable_ransackable_attributes)
    end
  end

  describe "ransackable associations" do
    it "includes authorizable ransackable associations" do
      expect(BoardLog.ransackable_associations).to eq(BoardLog.authorizable_ransackable_associations)
    end
  end


end