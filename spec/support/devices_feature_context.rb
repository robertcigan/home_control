RSpec.shared_context "devices feature setup" do
  let!(:arduino_board) { create(:board, name: "Arduino Board", ip: "192.168.1.10") }
  let!(:esp_board) { create(:board, :with_wifi, name: "ESP Board", ip: "192.168.1.20") }
  let!(:modbus_board) { create(:board, :modbus_tcp, name: "Modbus Board", ip: "192.168.1.30") }

  let!(:switch_device) { create(:switch, name: "Test Switch", board: arduino_board, pin: 1) }
  let!(:relay_device) { create(:relay, name: "Test Arduino Relay", board: arduino_board, pin: 2) }
  let!(:analog_device) { create(:analog_input, name: "Test Analog", board: arduino_board, pin: 3) }
  let!(:esp_relay_device) { create(:relay, name: "Test ESP Relay", board: esp_board, pin: 4) }
end
