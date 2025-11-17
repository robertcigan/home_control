require "rails_helper"

RSpec.describe Program, type: :model do
  let(:program) { create(:program) }

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:program_type) }
  end

  describe "associations" do
    it { should have_many(:programs_devices).dependent(:destroy) }
    it { should have_many(:devices).through(:programs_devices) }
    it { should have_many(:widgets).dependent(:destroy) }
  end

  describe ".default" do
    let!(:default_program) { create(:program) }
    let!(:repeated_program) { create(:program, :repeated) }

    it "returns only default programs" do
      expect(Program.default).to include(default_program)
      expect(Program.default).not_to include(repeated_program)
    end
  end

  describe ".repeated" do
    let!(:default_program) { create(:program) }
    let!(:repeated_program) { create(:program, :repeated) }

    it "returns only repeated programs" do
      expect(Program.repeated).to include(repeated_program)
      expect(Program.repeated).not_to include(default_program)
    end
  end

  describe ".repeated_to_run" do
    let!(:enabled_repeated) { create(:program, :repeated, enabled: true, repeat_every: 1, last_run: 1.minute.ago) }
    let!(:disabled_repeated) { create(:program, :repeated, enabled: false, last_run: 1.second.ago) }
    let!(:default_program) { create(:program, enabled: true) }

    it "returns only enabled repeated programs ready to run" do
      expect(Program.repeated_to_run).to include(enabled_repeated)
      expect(Program.repeated_to_run).not_to include(disabled_repeated)
      expect(Program.repeated_to_run).not_to include(default_program)
    end
  end

  describe "#to_s" do
    it "returns the program name" do
      program.name = "Test Program"
      expect(program.to_s).to eq("Test Program")
    end
  end

  describe "#run" do
    it "executes the program and updates timestamps" do
      program.update!(code: "string = \"Hello World\"; sleep 0.1;")
      expect { program.run }.to change { program.reload.last_run }
    end

    it "updates runtime" do
      program.update!(code: "string = \"Hello World\"; sleep 0.1;")
      program.run
      expect(program.runtime).to be > 0
    end

    it "handles successful execution" do
      program.update!(code: "string = \"Hello World\"; sleep 0.1;")
      program.run
      expect(program.last_error_at).to be_nil
      expect(program.last_error_message).to be_nil
    end

    it "handles execution errors" do
      program.code = "invalid ruby code"
      program.save
      expect { program.run }.not_to raise_error
      expect(program.last_error_at).to be_present
      expect(program.last_error_message).to be_present
    end
  end

  describe "#thread_utilisation" do
    it "calculates thread utilisation based on repeat_every for repeated programs with runtime" do
      program.runtime = 100
      program.program_type = "repeated"
      program.repeat_every = 10
      expect(program.thread_utilisation).to eq(1.0)
    end

    it "calculates thread utilisation based on time since last_run for default programs with runtime" do
      program.runtime = 100
      program.program_type = "default"
      program.last_run = 1.hour.ago
      expect(program.thread_utilisation).to be > 0
    end

    it "returns 0.0 for default programs without last_run and with runtime" do
      program.runtime = 100
      program.program_type = "default"
      program.last_run = nil
      expect(program.thread_utilisation).to eq(0.0)
    end

    it "returns 0.0 without runtime" do
      expect(program.thread_utilisation).to eq(0.0)
    end
  end

  describe "#set" do
    it "sets a value in storage" do
      program.set("test_key", "test_value")
      expect(program.storage["test_key"]).to eq("test_value")
    end
  end

  describe "#get" do
    it "gets a value from storage" do
      program.storage = { "test_key" => "test_value" }
      expect(program.get("test_key")).to eq("test_value")
    end

    it "returns nil for non-existent key" do
      expect(program.get("non_existent")).to be_nil
    end
  end

  describe "#last_run_text" do
    it "returns formatted last_run time when present" do
      program.last_run = Time.parse("2023-01-01 12:00:00")
      expect(program.last_run_text).to be_present
    end

    it "returns nil when last_run is nil" do
      program.last_run = nil
      expect(program.last_run_text).to be_nil
    end
  end

  describe "#last_error_at_text" do
    it "returns formatted last_error_at time when present" do
      program.last_error_at = Time.parse("2023-01-01 12:00:00")
      expect(program.last_error_at_text).to be_present
    end

    it "returns nil when last_error_at is nil" do
      program.last_error_at = nil
      expect(program.last_error_at_text).to be_nil
    end
  end

  describe "#json_data" do
    it "includes program-specific data" do
      program.enabled = true
      program.runtime = 100
      program.last_run = Time.current
      json_data = program.json_data

      expect(json_data).to include(:enabled, :runtime, :"thread-utilisation", :"last-run", :"last-error-at", :"has-error")
    end
  end

  describe "#has_error?" do
    it "returns true when last_run equals last_error_at" do
      time = Time.current
      program.last_run = time
      program.last_error_at = time
      expect(program.has_error?).to be true
    end

    it "returns false when last_run does not equal last_error_at" do
      program.last_run = Time.current
      program.last_error_at = 1.hour.ago
      expect(program.has_error?).to be false
    end

    it "returns false when last_error_at is nil" do
      program.last_run = Time.current
      program.last_error_at = nil
      expect(program.has_error?).to be false
    end
  end

  describe "#set_default_storage" do
    it "sets empty hash for nil storage" do
      program.storage = nil
      program.save!
      expect(program.storage).to eq({})
    end
  end

  describe "#precompile_code" do
    it "compiles code when code changes" do
      expect { program.update(code: "s = \"Hello changed\"") }.to change { program.compiled_code }
    end

    it "compiles code when compiled_code is blank but code is present" do
      program.code = "s = \"Hello World\""
      program.compiled_code = nil
      expect { program.save! }.to change { program.compiled_code }.to("\ns = \"Hello World\"")
    end
  end
end