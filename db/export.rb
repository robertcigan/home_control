# Export script to CSV
require 'csv'
[Board, Device, Program, Panel, Widget, ProgramsDevice, BoardLog, DeviceLog].each do |model|
  CSV.open("tmp/export/#{model.to_s.downcase}.csv", "wb") do |csv|
    # csv << model.first.attributes.keys
    model.order(:id).find_each do |record|
      csv << record.attributes.values
    end
  end
end