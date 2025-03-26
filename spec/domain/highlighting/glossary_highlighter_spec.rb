require "rails_helper"

RSpec.describe Highlighting::GlossaryHighlighter do
  let(:glossary) { create(:glossary, source_language_code: "en", target_language_code: "fr") }

  def translation_for(text, glossary_record = glossary)
    create(:translation,
      source_language_code: "en",
      target_language_code: "fr",
      source_text: text,
      glossary: glossary_record)
  end

  it "returns the text unchanged when there is no glossary" do
    expect(described_class.call(translation_for("the cat sat", nil))).to eq("the cat sat")
  end

  it "returns the text unchanged when the glossary has no terms" do
    expect(described_class.call(translation_for("the cat sat"))).to eq("the cat sat")
  end

  it "wraps matching terms with the default markup" do
    create(:term, source_term: "cat", target_term: "chat", glossary: glossary)

    expect(described_class.call(translation_for("the cat sat")))
      .to eq("the <HIGHLIGHT>cat</HIGHLIGHT> sat")
  end

  it "renders with a different registered markup style" do
    create(:term, source_term: "cat", target_term: "chat", glossary: glossary)

    expect(described_class.call(translation_for("the cat sat"), markup: :mark))
      .to eq("the <mark>cat</mark> sat")
  end

  it "raises for an unregistered markup style" do
    expect { described_class.call(translation_for("the cat sat"), markup: :neon) }
      .to raise_error(Highlighting::Markup::Unknown)
  end

  it "produces the same output under either strategy" do
    create(:term, source_term: "New York", target_term: "New York", glossary: glossary)
    create(:term, source_term: "New", target_term: "Nouveau", glossary: glossary)
    translation = translation_for("New York is big")

    expect(described_class.call(translation, strategy: :regexp))
      .to eq(described_class.call(translation, strategy: :automaton))
  end

  describe "case sensitivity" do
    it "is case sensitive by default" do
      create(:term, source_term: "cat", target_term: "chat", glossary: glossary)

      expect(described_class.call(translation_for("the Cat sat"))).to eq("the Cat sat")
    end

    it "matches regardless of case on a case-insensitive glossary" do
      insensitive = create(:glossary, source_language_code: "en", target_language_code: "de",
        case_sensitive: false)
      create(:term, source_term: "cat", target_term: "Katze", glossary: insensitive)
      translation = create(:translation, source_language_code: "en", target_language_code: "de",
        source_text: "the Cat sat", glossary: insensitive)

      expect(described_class.call(translation)).to eq("the <HIGHLIGHT>Cat</HIGHLIGHT> sat")
    end

    it "preserves the original casing of the matched text" do
      insensitive = create(:glossary, source_language_code: "en", target_language_code: "de",
        case_sensitive: false)
      create(:term, source_term: "CAT", target_term: "Katze", glossary: insensitive)
      translation = create(:translation, source_language_code: "en", target_language_code: "de",
        source_text: "the CaT sat", glossary: insensitive)

      expect(described_class.call(translation)).to eq("the <HIGHLIGHT>CaT</HIGHLIGHT> sat")
    end
  end

  describe "matcher caching" do
    let!(:term) { create(:term, source_term: "cat", target_term: "chat", glossary: glossary) }
    let(:translation) { translation_for("the cat sat and the dog barked") }

    it "builds the matcher once for repeated renders of the same glossary" do
      # One term, so the adaptive strategy resolves to the regexp matcher.
      allow(Highlighting::RegexpMatcher).to receive(:new).and_call_original

      3.times { described_class.call(translation.reload) }

      expect(Highlighting::RegexpMatcher).to have_received(:new).once
    end

    it "builds a separate matcher for a different glossary" do
      allow(Highlighting::RegexpMatcher).to receive(:new).and_call_original
      other = create(:glossary, source_language_code: "en", target_language_code: "de")
      create(:term, source_term: "dog", target_term: "Hund", glossary: other)
      other_translation = create(:translation, source_language_code: "en", target_language_code: "de",
        source_text: "the dog barked", glossary: other)

      described_class.call(translation)
      described_class.call(other_translation)

      expect(Highlighting::RegexpMatcher).to have_received(:new).twice
    end

    it "rebuilds after a term is added" do
      expect(described_class.call(translation)).to eq("the <HIGHLIGHT>cat</HIGHLIGHT> sat and the dog barked")

      create(:term, source_term: "dog", target_term: "chien", glossary: glossary)

      expect(described_class.call(translation.reload))
        .to eq("the <HIGHLIGHT>cat</HIGHLIGHT> sat and the <HIGHLIGHT>dog</HIGHLIGHT> barked")
    end

    it "rebuilds after a term is changed" do
      term.update!(source_term: "dog")

      expect(described_class.call(translation.reload))
        .to eq("the cat sat and the <HIGHLIGHT>dog</HIGHLIGHT> barked")
    end

    it "rebuilds after a term is destroyed" do
      term.destroy!

      expect(described_class.call(translation.reload)).to eq("the cat sat and the dog barked")
    end
  end
end
