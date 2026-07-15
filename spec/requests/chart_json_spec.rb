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
end
