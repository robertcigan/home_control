require "rails_helper"

RSpec.describe "Device logs chart JSON", type: :request do
  let!(:device) { create(:virtual_integer, name: "Chart Device", value_integer: 50) }
  let(:frozen_time) { Time.zone.parse("2025-06-15 12:30:00") }

  before do
    create(:device_log, :with_integer_value, device: device, value_integer: 10,
      created_at: frozen_time.beginning_of_day + 2.hours)
    create(:device_log, :with_integer_value, device: device, value_integer: 20,
      created_at: frozen_time.beginning_of_day + 4.hours)
    create(:device_log, :with_integer_value, device: device, value_integer: 30,
      created_at: frozen_time.beginning_of_day + 6.hours)
    create(:device_log, :with_integer_value, device: device, value_integer: 5,
      created_at: frozen_time.beginning_of_day - 2.hours)
    create(:device_log, :with_integer_value, device: device, value_integer: 99,
      created_at: frozen_time.end_of_day + 1.hour)
  end

  it "returns series data for the default day timespan" do
    Timecop.freeze(frozen_time) do
      get chart_device_device_logs_path(device, format: :json, timespan: "day")
      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data).to be_an(Array)
      expect(data.first).to be_an(Array)
      expect(data.map(&:last)).to include(10, 20, 30)
    end
  end

  it "prepends value before window min and appends value after window max" do
    Timecop.freeze(frozen_time) do
      min = frozen_time.beginning_of_day
      max = frozen_time.end_of_day
      get chart_device_device_logs_path(device, format: :json, timespan: "day", min: min, max: max)
      data = JSON.parse(response.body)
      values = data.map(&:last)
      expect(values.first).to eq(5)
      expect(values.last).to eq(99)
    end
  end

  it "aggregates numeric series when over the point cap" do
    Timecop.freeze(frozen_time) do
      stub_const("DeviceLog::MAX_CHART_POINTS", 10)
      min = frozen_time.beginning_of_day
      max = frozen_time.end_of_day
      cap = DeviceLog::MAX_CHART_POINTS

      (cap + 20).times do |i|
        create(:device_log, :with_integer_value, device: device, value_integer: i,
          created_at: min + (i * 2).minutes)
      end

      series = DeviceLog.chart_series(device, min, max)
      expect(series.length).to be <= cap
      expect(series.map(&:last).compact).to all(be_a(Numeric))

      get chart_device_device_logs_path(device, format: :json, timespan: "day", min: min, max: max)
      data = JSON.parse(response.body)
      expect(data.length).to be <= (cap + 2)
      expect(data.map(&:last)).to all(be_a(Numeric).or(be_nil))
    end
  end

  it "keeps all boolean points without averaging or sampling" do
    board = create(:board, name: "Bool Board", ip: "192.168.1.200")
    bool_device = create(:relay, name: "Bool Chart", board: board, pin: 8, log_enabled: true)
    frozen = frozen_time
    min = frozen.beginning_of_day
    max = frozen.end_of_day
    cap = 5

    12.times do |i|
      create(:device_log, :with_boolean_value, device: bool_device, value_boolean: i.even?,
        created_at: min + i.minutes)
    end

    series = DeviceLog.chart_series(bool_device, min, max, cap: cap)
    expect(series.length).to eq(12)
    expect(series.map(&:last)).to all(be_in([0, 1]))

    extra = (4 * cap) + 5
    extra.times do |i|
      create(:device_log, :with_boolean_value, device: bool_device, value_boolean: i.odd?,
        created_at: min + (20 + i).minutes)
    end

    full_series = DeviceLog.chart_series(bool_device, min, max, cap: cap)
    expect(full_series.length).to eq(12 + extra)
    expect(full_series.map(&:last)).to all(be_in([0, 1]))
  end
end
