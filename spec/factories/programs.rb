FactoryBot.define do
  factory :program do
    sequence(:name) { |n| "Program #{n}" }
    program_type { Program::ProgramType::DEFAULT }
    code { "string = 'Hello World'" }
    enabled { false }
    runtime { 0 }
    storage { nil }
    compiled_code { nil }
    output { nil }

    trait :repeated do
      program_type { Program::ProgramType::REPEATED }
      repeat_every { 10 }
    end
  end
end