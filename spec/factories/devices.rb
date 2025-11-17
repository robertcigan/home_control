FactoryBot.define do
  # Device factory (base)
  factory :device, class: 'Device' do
    board
    sequence(:name) { |n| "Device #{n}" }
    device_type { "Device::Switch" }
    pin { 1 }
    inverted { false }
    poll { 1000 }
    unit { nil }
    log_enabled { true }
    virtual_writable { false }

    trait :relay do
      device_type { "Device::Relay" }
      value_boolean { false }
    end

    trait :switch do
      device_type { "Device::Switch" }
      value_boolean { false }
    end

    trait :analog_input do
      device_type { "Device::AnalogInput" }
      value_decimal { 0.0 }
    end

    trait :button do
      device_type { "Device::Button" }
      value_boolean { false }
    end

    trait :curtain do
      device_type { "Device::Curtain" }
      value_integer { 0 }
    end

    trait :distance do
      device_type { "Device::Distance" }
      value_integer { 0 }
    end

    trait :ds18b20 do
      device_type { "Device::Ds18b20" }
      value_decimal { 20.0 }
    end

    trait :pwm do
      device_type { "Device::Pwm" }
      value_integer { 0 }
    end

    trait :sound do
      device_type { "Device::Sound" }
      value_boolean { false }
    end

    trait :virtual_boolean do
      device_type { "Device::VirtualBoolean" }
      value_boolean { false }
      virtual_writable { true }
    end

    trait :virtual_decimal do
      device_type { "Device::VirtualDecimal" }
      value_decimal { 0.0 }
    end

    trait :virtual_integer do
      device_type { "Device::VirtualInteger" }
      value_integer { 0 }
    end

    trait :virtual_string do
      device_type { "Device::VirtualString" }
      value_string { "test" }
    end

    trait :board_test do
      device_type { "Device::BoardTest" }
      value_boolean { false }
    end

    trait :with_compression do
      compression_type { "average" }
      compression_timespan { "min5" }
      compression_backlog { 10 }
    end

    trait :with_log_clearing do
      days_to_preserve_logs { 7 }
    end

    trait :modbus do
      holding_register_address { 1 }
      modbus_data_type { "uint16" }
      scale { 1 }
    end
  end

  # Specific device type factories
  factory :relay, class: 'Device::Relay', parent: :device do
    device_type { "Device::Relay" }
    value_boolean { false }
  end

  factory :switch, class: 'Device::Switch', parent: :device do
    device_type { "Device::Switch" }
    value_boolean { false }
  end

  factory :analog_input, class: 'Device::AnalogInput', parent: :device do
    device_type { "Device::AnalogInput" }
    value_decimal { 0.0 }
  end

  factory :button, class: 'Device::Button', parent: :device do
    device_type { "Device::Button" }
    value_boolean { false }
  end

  factory :curtain, class: 'Device::Curtain', parent: :device do
    device_type { "Device::Curtain" }
    value_integer { 0 }
  end

  factory :distance, class: 'Device::Distance', parent: :device do
    device_type { "Device::Distance" }
    value_integer { 0 }
  end

  factory :ds18b20, class: 'Device::Ds18b20', parent: :device do
    device_type { "Device::Ds18b20" }
    value_decimal { 20.0 }
  end

  factory :pwm, class: 'Device::Pwm', parent: :device do
    device_type { "Device::Pwm" }
    value_integer { 0 }
  end

  factory :sound, class: 'Device::Sound', parent: :device do
    device_type { "Device::Sound" }
    value_boolean { false }
  end

  factory :virtual_boolean, class: 'Device::VirtualBoolean', parent: :device do
    device_type { "Device::VirtualBoolean" }
    value_boolean { false }
    virtual_writable { true }

    trait :modbus_writable do
      board { association :board, :modbus_tcp }
      virtual_writable { true }
      holding_register_address { 1 }
      modbus_data_type { "uint16" }
      scale { 1 }
    end

    trait :modbus_readable do
      board { association :board, :modbus_tcp }
      virtual_writable { false }
      holding_register_address { 1 }
      modbus_data_type { "uint16" }
      scale { 1 }
    end
  end

  factory :virtual_decimal, class: 'Device::VirtualDecimal', parent: :device do
    device_type { "Device::VirtualDecimal" }
    value_decimal { 0.0 }
    board { nil }
    pin { nil }

    trait :modbus_writable do
      board { association :board, :modbus_tcp }
      virtual_writable { true }
      holding_register_address { 1 }
      modbus_data_type { "uint16" }
      scale { 1 }
    end

    trait :modbus_readable do
      board { association :board, :modbus_tcp }
      virtual_writable { false }
      holding_register_address { 1 }
      modbus_data_type { "uint16" }
      scale { 1 }
    end
  end

  factory :virtual_integer, class: 'Device::VirtualInteger', parent: :device do
    device_type { "Device::VirtualInteger" }
    value_integer { 0 }
    board { nil }
    pin { nil }

    trait :modbus_writable do
      board { association :board, :modbus_tcp }
      virtual_writable { true }
      holding_register_address { 1 }
      modbus_data_type { "uint16" }
      scale { 1 }
    end

    trait :modbus_readable do
      board { association :board, :modbus_tcp }
      virtual_writable { false }
      holding_register_address { 1 }
      modbus_data_type { "uint16" }
      scale { 1 }
    end
  end

  factory :virtual_string, class: 'Device::VirtualString', parent: :device do
    device_type { "Device::VirtualString" }
    value_string { "test" }
    board { nil }
    pin { nil }

    trait :modbus_writable do
      board { association :board, :modbus_tcp }
      virtual_writable { true }
      holding_register_address { 1 }
      modbus_data_type { "uint16" }
      scale { 1 }
    end

    trait :modbus_readable do
      board { association :board, :modbus_tcp }
      virtual_writable { false }
      holding_register_address { 1 }
      modbus_data_type { "uint16" }
      scale { 1 }
    end
  end

  factory :board_test, class: 'Device::BoardTest', parent: :device do
    device_type { "Device::BoardTest" }
    value_boolean { false }
  end
end