FactoryBot.define do
  factory :device_log do
    device
    value_integer { nil }
    value_boolean { nil }
    value_string { nil }
    value_decimal { nil }

    trait :with_boolean_value do
      value_boolean { true }
    end

    trait :with_integer_value do
      value_integer { 100 }
    end

    trait :with_decimal_value do
      value_decimal { 25.5 }
    end

    trait :with_string_value do
      value_string { "test_value" }
    end
  end
end