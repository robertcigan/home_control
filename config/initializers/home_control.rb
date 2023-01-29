Rails.application.configure do
  config.home_control = OpenStruct.new(
    version: "3.0",
    luxon_formats: {
      second: "HH:mm:ss",
      minute: "HH:mm",
      hour: "d.L.y HH'h'",
      day: "d.L.y",
      week: "W't' y",
      month: "L.y",
      quarter: "q'k' y",
      time: "d.L.y HH:mm:ss"
    },
    authentication: {
      name: "home",
      password: "control"
    }
  )
end