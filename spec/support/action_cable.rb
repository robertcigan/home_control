RSpec.configure do |config|
  config.include ActionCable::TestHelper, type: :model
  config.include ActionCable::TestHelper, type: :channel
  config.include ActionCable::TestHelper, type: :request

  config.before do |example|
    if example.metadata[:type].in?(%i[model channel request])
      ActionCable.server.pubsub.clear
    end
  end
end
