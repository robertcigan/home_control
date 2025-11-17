require 'rails_helper'

RSpec.describe DeviceLog, type: :model do
  describe 'associations' do
    it { should belong_to(:device) }
  end

  describe 'scopes' do
    let!(:device) { create(:device) }
    let!(:recent_log) { create(:device_log, device: device, created_at: 1.hour.ago) }
    let!(:old_log) { create(:device_log, device: device, created_at: 1.day.ago) }

    describe '.recent' do
      it 'returns the 20 most recent logs ordered by created_at DESC' do
        expect(DeviceLog.recent).to include(recent_log, old_log)
        expect(DeviceLog.recent.first).to eq(recent_log)
      end
    end
  end

  describe '#chart_data' do
    let(:device) { create(:device) }

    it 'returns chart data with boolean value' do
      device_log = create(:device_log, device: device, value_boolean: true)
      chart_data = device_log.chart_data
      expect(chart_data[0]).to eq(device_log.created_at.to_s)
      expect(chart_data[1]).to eq(1)
    end

    it 'returns chart data with integer value' do
      device_log = create(:device_log, device: device, value_integer: 100)
      chart_data = device_log.chart_data
      expect(chart_data[0]).to eq(device_log.created_at.to_s)
      expect(chart_data[1]).to eq(100)
    end

    it 'returns chart data with decimal value' do
      device_log = create(:device_log, device: device, value_decimal: 25.5)
      chart_data = device_log.chart_data
      expect(chart_data[0]).to eq(device_log.created_at.to_s)
      expect(chart_data[1]).to eq(25.5)
    end

    it 'returns chart data with default value when no value is present' do
      device_log = create(:device_log, device: device)
      chart_data = device_log.chart_data
      expect(chart_data[0]).to eq(device_log.created_at.to_s)
      expect(chart_data[1]).to eq(1)
    end
  end

  describe '#indication' do
    let(:device) { create(:device) }

    it 'returns indication for boolean value' do
      device_log = create(:device_log, device: device, value_boolean: true)
      expect(device_log.indication).to eq('on')
    end

    it 'returns indication for integer value' do
      device_log = create(:device_log, device: device, value_integer: 100)
      expect(device_log.indication).to eq(100)
    end

    it 'returns indication for decimal value' do
      device_log = create(:device_log, device: device, value_decimal: 25.5)
      expect(device_log.indication).to eq(25.5)
    end

    it 'returns indication for string value' do
      device_log = create(:device_log, device: device, value_string: 'test_value')
      expect(device_log.indication).to eq('test_value')
    end

    it 'returns formatted updated_at when no value is present' do
      device_log = create(:device_log, device: device)
      expect(device_log.indication).to be_present
    end
  end

  describe '.ransackable_attributes' do
    it 'returns authorizable ransackable attributes' do
      expect(DeviceLog.ransackable_attributes).to eq(DeviceLog.authorizable_ransackable_attributes)
    end
  end

  describe '.ransackable_associations' do
    it 'returns authorizable ransackable associations' do
      expect(DeviceLog.ransackable_associations).to eq(DeviceLog.authorizable_ransackable_associations)
    end
  end
end