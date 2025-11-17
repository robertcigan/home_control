require 'rails_helper'

RSpec.describe Device, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:device_type) }
    it { should validate_uniqueness_of(:pin).scoped_to(:board_id).allow_nil }

    it 'requires holding_register_address when board is modbus_tcp' do
      board = create(:board, :modbus_tcp)
      device = build(:device, board: board)
      device.holding_register_address = nil
      expect(device).not_to be_valid
      expect(device.errors[:holding_register_address]).to include("can't be blank")
    end

    it 'requires compression_timespan when compression_type is present' do
      device = build(:device, :with_compression)
      device.compression_timespan = nil
      expect(device).not_to be_valid
      expect(device.errors[:compression_timespan]).to include("can't be blank")
    end

    it 'requires compression_backlog when compression_type is present' do
      device = build(:device, :with_compression)
      device.compression_backlog = nil
      expect(device).not_to be_valid
      expect(device.errors[:compression_backlog]).to include("can't be blank")
    end
  end

  describe 'associations' do
    it { should have_many(:device_logs).dependent(:delete_all) }
    it { should have_many(:programs_devices).dependent(:destroy) }
    it { should have_many(:programs).through(:programs_devices) }
    it { should have_many(:widgets).dependent(:destroy) }
    it { should belong_to(:board).optional }
  end

  describe '.board' do
    let!(:board1) { create(:board, ip: '192.168.1.10') }
    let!(:board2) { create(:board, ip: '192.168.1.20') }
    let!(:device1) { create(:device, board: board1) }
    let!(:device2) { create(:device, board: board2) }

    it 'filters devices by board ip' do
      expect(Device.board('192.168.1.10')).to include(device1)
      expect(Device.board('192.168.1.10')).not_to include(device2)
    end
  end

  describe '.repeated_ws_push' do
    let!(:device) { create(:device) }
    let!(:widget) { create(:widget, :type_switch, device: device) }

    it 'returns devices with widgets that were updated more than 60 seconds ago' do
      device.update!(updated_at: 2.minutes.ago)
      expect(Device.repeated_ws_push).to include(device)
    end
  end

  describe '.for_compression' do
    let!(:device_with_compression) { create(:device, :with_compression, log_enabled: true) }
    let!(:device_without_compression) { create(:device, log_enabled: true) }

    it 'returns devices with compression enabled and log_enabled' do
      expect(Device.for_compression).to include(device_with_compression)
      expect(Device.for_compression).not_to include(device_without_compression)
    end
  end

  describe '.for_log_clear' do
    let!(:device_with_log_clearing) { create(:device, :with_log_clearing) }
    let!(:device_without_log_clearing) { create(:device) }

    it 'returns devices with days_to_preserve_logs set' do
      expect(Device.for_log_clear).to include(device_with_log_clearing)
      expect(Device.for_log_clear).not_to include(device_without_log_clearing)
    end
  end

  describe '.device_type_relay' do
    let!(:relay) { create(:relay) }
    let!(:switch) { create(:switch) }

    it 'returns only relay devices' do
      expect(Device.device_type_relay).to include(relay)
      expect(Device.device_type_relay).not_to include(switch)
    end
  end

  describe '.device_type_switch' do
    let!(:relay) { create(:relay) }
    let!(:switch) { create(:switch) }

    it 'returns only switch devices' do
      expect(Device.device_type_switch).to include(switch)
      expect(Device.device_type_switch).not_to include(relay)
    end
  end

  describe '.device_type_analog_input' do
    let!(:analog_input) { create(:analog_input) }
    let!(:relay) { create(:relay) }

    it 'returns only analog input devices' do
      expect(Device.device_type_analog_input).to include(analog_input)
      expect(Device.device_type_analog_input).not_to include(relay)
    end
  end

  describe '#to_s' do
    let(:device) { create(:device, name: 'Test Device') }

    it 'returns the device name' do
      expect(device.to_s).to eq('Test Device')
    end

    it 'returns UNKNOWN for devices without name' do
      device.name = nil
      expect(device.to_s).to eq('UNKNOWN')
    end
  end

  describe '#last_change_text' do
    let(:device) { create(:device) }

    it 'returns formatted last_change time' do
      device.last_change = Time.current
      expect(device.last_change_text).to be_present
    end

    it 'returns nil when last_change is nil' do
      device.last_change = nil
      expect(device.last_change_text).to be_nil
    end
  end

  describe '#json_data' do
    let(:device) { create(:device) }

    it 'includes status, updated, value, and indication' do
      device.value_boolean = true
      device.last_change = Time.current
      json_data = device.json_data

      expect(json_data).to include(:id, :status, :updated, :value, :indication)
      expect(json_data[:id]).to eq(device.id)
      expect(json_data[:status]).to eq("")
      expect(json_data[:value]).to eq("")
      expect(json_data[:indication]).to eq("")
      expect(json_data[:updated]).to be_present
    end
  end

  describe '#status' do
    let(:device) { create(:device) }

    it 'returns nil by default' do
      expect(device.status).to be_nil
    end
  end

  describe '#readable?' do
    let(:device) { create(:device) }

    it 'returns false by default' do
      expect(device.readable?).to be false
    end
  end

  describe '#writable?' do
    let(:device) { create(:device) }

    it 'returns false by default' do
      expect(device.writable?).to be false
    end
  end

  describe '#toggle?' do
    let(:device) { create(:device) }

    it 'returns false by default' do
      expect(device.toggle?).to be false
    end
  end

  describe '#poll?' do
    let(:device) { create(:device) }

    it 'returns false by default' do
      expect(device.poll?).to be false
    end
  end

  describe '#indication' do
    it 'includes unit in indication when unit is present' do
      device = create(:device, unit: 'V', value_decimal: 12.5)
      expect(device.indication).to eq('V')
    end
  end

  describe '#value' do
    let(:device) { create(:device) }

    it 'returns nil by default' do
      expect(device.value).to be_nil
    end
  end

  describe '#value_attribute' do
    let(:device) { create(:device) }

    it 'returns nil by default' do
      expect(device.value_attribute).to be_nil
    end
  end

  describe '#get_current_chart_data' do
    it 'returns 1 for true boolean value' do
      device = create(:device, value_boolean: true)
      expect(device.get_current_chart_data).to eq(1)
    end

    it 'returns 0 for false boolean value' do
      device = create(:device, value_boolean: false)
      expect(device.get_current_chart_data).to eq(0)
    end

    it 'includes unit when present for integer value' do
      device = create(:device, value_integer: 100, unit: 'A')
      expect(device.get_current_chart_data).to eq('100A')
    end

    it 'returns integer without unit when unit is nil' do
      device = create(:device, value_integer: 100, unit: nil)
      expect(device.get_current_chart_data).to eq(100)
    end

    it 'includes unit when present for decimal value' do
      device = create(:device, value_decimal: 25.5, unit: '°C')
      expect(device.get_current_chart_data).to eq('25.5°C')
    end

    it 'returns decimal without unit when unit is nil' do
      device = create(:device, value_decimal: 25.5, unit: nil)
      expect(device.get_current_chart_data).to eq(25.5)
    end

    it 'returns 1 as default when no value is present' do
      device = create(:device)
      expect(device.get_current_chart_data).to eq(1)
    end
  end

  describe '#clear_logs' do
    let!(:device) { create(:device, days_to_preserve_logs: 7) }
    let!(:old_log) { create(:device_log, device: device, created_at: 10.days.ago) }
    let!(:recent_log) { create(:device_log, device: device, created_at: 1.day.ago) }

    it 'deletes logs older than days_to_preserve_logs' do
      expect { device.clear_logs }.to change { device.device_logs.count }.by(-1)
      expect(device.device_logs).to include(recent_log)
      expect(device.device_logs).not_to include(old_log)
    end
  end

  describe '#send_to_board' do
    let!(:board) { create(:board) }
    let!(:device) { create(:device, board: board) }

    it 'delegates to board send_to_board method' do
      expect(board).to receive(:send_to_board).with('test_data')
      device.send_to_board('test_data')
    end
  end

  describe '#device_type_relay?' do
    let(:relay) { create(:relay) }
    let(:switch) { create(:switch) }

    it 'returns true for relay devices' do
      expect(relay.device_type_relay?).to be true
    end

    it 'returns false for non-relay devices' do
      expect(switch.device_type_relay?).to be false
    end
  end

  describe '#device_type_switch?' do
    let(:relay) { create(:relay) }
    let(:switch) { create(:switch) }

    it 'returns true for switch devices' do
      expect(switch.device_type_switch?).to be true
    end

    it 'returns false for non-switch devices' do
      expect(relay.device_type_switch?).to be false
    end
  end

  describe '#device_type_analog_input?' do
    let(:analog_input) { create(:analog_input) }
    let(:relay) { create(:relay) }

    it 'returns true for analog input devices' do
      expect(analog_input.device_type_analog_input?).to be true
    end

    it 'returns false for non-analog input devices' do
      expect(relay.device_type_analog_input?).to be false
    end
  end

  describe '#trigger_programs' do
    let!(:device) { create(:device) }
    let!(:program) { create(:program, enabled: true) }
    let!(:programs_device) { create(:programs_device, program: program, device: device, trigger: true) }

    it 'runs triggered programs' do
      expect_any_instance_of(Program).to receive(:run)
      device.send(:trigger_programs)
    end
  end

  describe '#log_device_log' do
    let(:device) { create(:device) }

    it 'is defined but does nothing by default' do
      expect { device.send(:log_device_log) }.not_to raise_error
    end
  end

  describe '#reset_pins' do
    let!(:board) { create(:board) }
    let!(:device) { create(:device, board: board) }

    it 'calls reset_devices and set_pins on board' do
      expect(board).to receive(:reset_devices)
      expect(board).to receive(:set_pins)
      device.send(:reset_pins)
    end
  end

  describe '#detect_log_enabled_change' do
    let!(:board) { create(:board) }
    let!(:device) { create(:device, board: board) }

    it 'deletes device_logs when log_enabled changes to false' do
      device.log_enabled = true
      device.save!
      create(:device_log, device: device)

      expect {
        device.update!(log_enabled: false)
      }.to change { device.device_logs.count }.to(0)
    end
  end

  describe '#reset_pins_after_create' do
    let(:board) { create(:board) }

    it 'calls reset_pins on board' do
      expect(board).to receive(:reset_devices)
      expect(board).to receive(:set_pins)
      create(:device, board: board)
    end
  end

  describe '#reset_pins_after_destroy' do
    let!(:board) { create(:board) }
    let!(:device) { create(:device, board: board) }

    it 'calls reset_pins on board' do
      expect(board).to receive(:reset_devices)
      expect(board).to receive(:set_pins)
      device.destroy
    end
  end

  describe '#detect_hw_change' do
    let!(:board) { create(:board) }
    let!(:device) { create(:device, :switch, board: board) }

    it 'resets pins when pin changes' do
      expect(board).to receive(:reset_devices)
      expect(board).to receive(:set_pins)
      device.update!(pin: device.pin + 1)
    end

    it 'resets pins when device_type changes' do
      expect(board).to receive(:reset_devices)
      expect(board).to receive(:set_pins)
      device.update!(device_type: Device::Button.name)
    end

    it 'resets pins when poll changes' do
      expect(board).to receive(:reset_devices)
      expect(board).to receive(:set_pins)
      device.update!(poll: 2000)
    end

    it 'resets pins when inverted changes' do
      expect(board).to receive(:reset_devices)
      expect(board).to receive(:set_pins)
      device.update!(inverted: true)
    end
  end

  describe '.ransackable_attributes' do
    it 'returns authorizable ransackable attributes' do
      expect(Device.ransackable_attributes).to eq(Device.authorizable_ransackable_attributes)
    end
  end

  describe '.ransackable_associations' do
    it 'returns authorizable ransackable associations' do
      expect(Device.ransackable_associations).to eq(Device.authorizable_ransackable_associations)
    end
  end
end