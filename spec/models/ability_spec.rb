require 'rails_helper'

RSpec.describe Ability, type: :model do
  describe 'initialization' do
    let(:user) { double('user') }
    let(:ability) { Ability.new(user) }

    it 'includes CanCan::Ability' do
      expect(Ability.included_modules).to include(CanCan::Ability)
    end

    it 'can manage all resources' do
      expect(ability.can?(:manage, :all)).to be true
    end

    it 'can read all resources' do
      expect(ability.can?(:read, :all)).to be true
    end

    it 'can create all resources' do
      expect(ability.can?(:create, :all)).to be true
    end

    it 'can update all resources' do
      expect(ability.can?(:update, :all)).to be true
    end

    it 'can destroy all resources' do
      expect(ability.can?(:destroy, :all)).to be true
    end
  end
end