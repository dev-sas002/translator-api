require "rails_helper"

# These examples exist to fail if an N+1 is reintroduced. They assert an exact
# count rather than a bound so that an accidental extra query is visible.
RSpec.describe "Query counts", type: :request do
  describe "GET /glossaries" do
    it "issues the same number of queries for one glossary as for many" do
      create(:glossary, source_language_code: "en", target_language_code: "fr")
        .then { |glossary| 3.times { |i| create(:term, source_term: "t#{i}", glossary: glossary) } }

      one = count_queries { get "/glossaries" }

      5.times do |index|
        glossary = create(:glossary, source_language_code: "en", target_language_code: Glossary::ISO_639_1_CODES[index])
        3.times { |i| create(:term, source_term: "t#{i}", glossary: glossary) }
      end

      many = count_queries { get "/glossaries" }

      expect(many.size).to eq(one.size), "N+1 on glossaries#index:\n#{many.join("\n")}"
    end

    it "loads glossaries and terms in two queries plus the count" do
      glossary = create(:glossary, source_language_code: "en", target_language_code: "fr")
      create(:term, source_term: "cat", glossary: glossary)

      queries = count_queries { get "/glossaries" }

      expect(queries.size).to eq(3)
    end
  end

  describe "GET /translations/:id" do
    it "issues the same number of queries however many terms the glossary has" do
      glossary = create(:glossary, source_language_code: "en", target_language_code: "fr")
      create(:term, source_term: "cat", glossary: glossary)
      translation = create(:translation, source_language_code: "en", target_language_code: "fr",
        source_text: "the cat sat", glossary: glossary)

      few = count_queries { get "/translations/#{translation.id}" }

      20.times { |index| create(:term, source_term: "term#{index}", glossary: glossary) }
      Highlighting::MatcherCache.instance.clear

      many = count_queries { get "/translations/#{translation.id}" }

      expect(many.size).to eq(few.size), "N+1 on translations#show:\n#{many.join("\n")}"
    end

    it "does not re-query the glossary terms once the matcher is cached" do
      glossary = create(:glossary, source_language_code: "en", target_language_code: "fr")
      create(:term, source_term: "cat", glossary: glossary)
      translation = create(:translation, source_language_code: "en", target_language_code: "fr",
        source_text: "the cat sat", glossary: glossary)

      cold = count_queries { get "/translations/#{translation.id}" }
      warm = count_queries { get "/translations/#{translation.id}" }

      expect(warm.size).to eq(cold.size - 1)
    end
  end
end
