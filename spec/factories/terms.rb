FactoryBot.define do
  factory :term do
    source_term { Faker::Lorem.word }
    target_term { Faker::Lorem.word }
    glossary { create(:glossary) }
  end
end
