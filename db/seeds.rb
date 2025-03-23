# Idempotent seed data, so a freshly booted container answers with something
# meaningful instead of empty collections. Safe to run repeatedly.
GLOSSARIES = {
  ["en", "fr"] => {
    case_sensitive: true,
    terms: {
      "cat" => "chat",
      "dog" => "chien",
      "New York" => "New York",
      "ice cream" => "glace",
      "open source" => "logiciel libre",
      "machine translation" => "traduction automatique"
    }
  },
  ["en", "de"] => {
    case_sensitive: false,
    terms: {
      "cat" => "Katze",
      "dog" => "Hund",
      "release notes" => "Versionshinweise",
      "pull request" => "Pull-Request"
    }
  },
  ["es", "en"] => {
    case_sensitive: true,
    terms: {
      "gato" => "cat",
      "código abierto" => "open source"
    }
  }
}.freeze

TRANSLATIONS = [
  {pair: ["en", "fr"], text: "The cat and the dog went to New York for ice cream."},
  {pair: ["en", "de"], text: "A Cat, a DOG and the release notes are in the pull request."},
  {pair: ["es", "en"], text: "El gato prefiere el código abierto."},
  {pair: ["en", "fr"], text: "This sentence has no glossary attached at all.", glossary: false}
].freeze

GLOSSARIES.each do |(source, target), attributes|
  glossary = Glossary.find_or_initialize_by(source_language_code: source, target_language_code: target)
  glossary.case_sensitive = attributes[:case_sensitive]
  glossary.save!

  attributes[:terms].each do |source_term, target_term|
    term = glossary.terms.find_or_initialize_by(source_term: source_term)
    term.target_term = target_term
    term.save!
  end
end

TRANSLATIONS.each do |attributes|
  source, target = attributes[:pair]
  glossary = (attributes[:glossary] == false) ? nil : Glossary.find_by!(source_language_code: source, target_language_code: target)

  translation = Translation.find_or_initialize_by(source_text: attributes[:text])
  translation.source_language_code = source
  translation.target_language_code = target
  translation.glossary = glossary
  translation.save!
end

puts "Seeded #{Glossary.count} glossaries, #{Term.count} terms, #{Translation.count} translations."
