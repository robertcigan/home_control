module RequestAuthHelpers
  def with_auth_headers
    {
      "HTTP_AUTHORIZATION" => "Basic " + Base64.strict_encode64("admin:password")
    }
  end

  def without_auth_headers
    {}
  end
end

RSpec.configure do |config|
  config.include RequestAuthHelpers, type: :request
end
