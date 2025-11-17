FactoryBot.define do
  factory :panel do
    sequence(:name) { |n| "Panel #{n}" }
    row { 12 }
    column { 12 }
    public_access { false }
  end
end