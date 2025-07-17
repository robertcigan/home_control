FactoryBot.define do
  factory :programs_device do
    association :program
    association :device
    variable_name { "device" }
    trigger { false }
  end
end