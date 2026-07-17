require "ostruct"
Rails.application.configure do
  config.home_control = OpenStruct.new(
    version: "3.5.2",
    authentication: {
      name: ENV["ADMIN_USERNAME"],
      password: ENV["ADMIN_PASSWORD"]
    }
  )
end
