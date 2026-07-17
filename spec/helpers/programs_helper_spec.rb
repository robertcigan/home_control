require "rails_helper"

RSpec.describe ProgramsHelper, type: :helper do
  include described_class

  describe "#time_between" do
    it "returns true when current time is inside the range" do
      Timecop.freeze(Time.zone.parse("2025-01-01 12:00:00")) do
        expect(time_between("10:00", "14:00")).to be true
      end
    end

    it "returns false when current time is outside the range" do
      Timecop.freeze(Time.zone.parse("2025-01-01 08:00:00")) do
        expect(time_between("10:00", "14:00")).to be false
      end
    end

    it "returns true on boundary start time" do
      Timecop.freeze(Time.zone.parse("2025-01-01 10:00:00")) do
        expect(time_between("10:00", "14:00")).to be true
      end
    end
  end

  describe "#program_log" do
    it "appends formatted output to program" do
      program = build(:program)
      program.extend(ProgramsHelper)
      program.output = ""
      program.log_info("hello")
      expect(program.output).to include("INFO: hello")
    end
  end
end
