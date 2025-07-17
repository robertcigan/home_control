FactoryBot.define do
  factory :board do
    sequence(:name) { |n| "Board #{n}" }
    sequence(:ip) { |n| "192.168.1.#{n}" }
    board_type { Board::BoardType::ARDUINO_MEGA_8B }
    version { 1 }
    data_read_interval { 5000 }
    days_to_preserve_logs { 30 }
    connected_at { nil }

    trait :modbus_tcp do
      board_type { Board::BoardType::MODBUS_TCP }
      slave_address { 1 }
    end

    trait :with_wifi do
      board_type { Board::BoardType::ESP }
      ssid { "TestWiFi" }
      signal_strength { 80 }
    end

    trait :disconnected do
      connected_at { nil }
    end
  end
end