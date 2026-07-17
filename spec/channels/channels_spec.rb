require "rails_helper"

RSpec.describe ArduinoChannel, type: :channel do
  it "subscribes to arduino stream" do
    subscribe
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from("arduino")
  end
end

RSpec.describe ModbusChannel, type: :channel do
  it "subscribes to modbus stream" do
    subscribe
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from("modbus")
  end
end

RSpec.describe BoardChannel, type: :channel do
  it "subscribes to boards stream" do
    subscribe
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from("boards")
  end
end

RSpec.describe DeviceChannel, type: :channel do
  it "subscribes to devices stream" do
    subscribe
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from("devices")
  end
end

RSpec.describe PanelChannel, type: :channel do
  it "subscribes to panels stream" do
    subscribe
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from("panels")
  end
end

RSpec.describe ProgramChannel, type: :channel do
  it "subscribes to programs stream" do
    subscribe
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from("programs")
  end
end
