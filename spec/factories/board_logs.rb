FactoryBot.define do
  factory :board_log do
    board
    connected { true }
    signal_strength { 80 }
    ssid { "TestWiFi" }

    trait :disconnected do
      connected { false }
    end
  end
end