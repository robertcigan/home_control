FactoryBot.define do
  factory :program do
    sequence(:name) { |n| "Program #{n}" }
    program_type { "default" }
    code { "string = 'Hello World'" }
    enabled { false }
    runtime { 0 }
    storage { nil }
    compiled_code { nil }
    output { nil }

    trait :repeated do
      program_type { "repeated" }
      repeat_every { 10 }
    end
  end
end