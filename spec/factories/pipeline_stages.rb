FactoryBot.define do
  factory :pipeline_stage do
    account { nil }
    name { "MyString" }
    position { 1 }
    color { "MyString" }
  end
end
