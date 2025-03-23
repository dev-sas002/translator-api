FactoryBot.define do
  factory :translation do
    source_language_code { "ab" }
    target_language_code { "af" }
    source_text { Faker::Lorem.paragraph }
    glossary { create(:glossary) }
  end
end
