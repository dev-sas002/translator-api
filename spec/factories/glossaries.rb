FactoryBot.define do
  factory :glossary do
    source_language_code { "ab" }
    target_language_code { "af" }
    case_sensitive { true }
  end
end
