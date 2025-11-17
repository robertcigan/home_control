require 'rails_helper'

RSpec.describe ProgramsDevice, type: :model do
  describe 'validations' do
    it { should belong_to(:device) }
    it { should belong_to(:program) }
  end

  describe 'associations' do
    let(:programs_device) { create(:programs_device) }

    it 'belongs to a device' do
      expect(programs_device.device).to be_a(Device)
    end

    it 'belongs to a program' do
      expect(programs_device.program).to be_a(Program)
    end
  end

  describe 'factory' do
    it 'creates a valid programs_device' do
      programs_device = create(:programs_device)
      expect(programs_device).to be_valid
      expect(programs_device.device).to be_present
      expect(programs_device.program).to be_present
    end
  end


end