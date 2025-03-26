require "rails_helper"

RSpec.describe ModifiedSourceTextSerializer, type: :model do
  subject(:highlighted) { described_class.new(translation).source_text }

  let(:glossary) { create(:glossary, source_language_code: "en", target_language_code: "fr") }

  def build_translation(text, glossary_record = glossary)
    create(:translation,
      source_language_code: "en",
      target_language_code: "fr",
      source_text: text,
      glossary: glossary_record)
  end

  context "when the translation has no glossary" do
    let(:translation) { build_translation("This is a nat test", nil) }

    it "returns the source text unchanged" do
      expect(highlighted).to eq("This is a nat test")
    end
  end

  context "when the glossary has no terms" do
    let(:translation) { build_translation("This is a nat test") }

    it "returns the source text unchanged" do
      expect(highlighted).to eq("This is a nat test")
    end
  end

  context "when a term matches" do
    let(:translation) { build_translation("This is a nat test") }

    before { create(:term, source_term: "is", target_term: "ist", glossary: glossary) }

    it "wraps whole-word occurrences only" do
      expect(highlighted).to eq("This <HIGHLIGHT>is</HIGHLIGHT> a nat test")
    end

    it "does not match a term embedded inside a longer word" do
      other = build_translation("Thistle island")
      expect(described_class.new(other).source_text).to eq("Thistle island")
    end

    it "does not mutate the persisted source text" do
      expect { highlighted }.not_to change { translation.reload.source_text }
    end

    it "is idempotent across repeated renders" do
      first = described_class.new(translation).source_text
      second = described_class.new(translation.reload).source_text
      expect(second).to eq(first)
    end
  end

  context "when the same term occurs several times" do
    let(:translation) { build_translation("a cat and a dog") }

    before { create(:term, source_term: "a", target_term: "un", glossary: glossary) }

    it "highlights every occurrence" do
      expect(highlighted).to eq("<HIGHLIGHT>a</HIGHLIGHT> cat and <HIGHLIGHT>a</HIGHLIGHT> dog")
    end
  end

  context "when terms overlap" do
    let(:translation) { build_translation("New York is big") }

    before do
      create(:term, source_term: "New", target_term: "Nouveau", glossary: glossary)
      create(:term, source_term: "New York", target_term: "New York", glossary: glossary)
    end

    it "prefers the longest term so the shorter one does not split the match" do
      expect(highlighted).to eq("<HIGHLIGHT>New York</HIGHLIGHT> is big")
    end
  end

  context "when a term collides with the highlight markup" do
    let(:translation) { build_translation("the HIGHLIGHT word") }

    before { create(:term, source_term: "HIGHLIGHT", target_term: "surlignage", glossary: glossary) }

    it "does not re-scan inserted markup and nest tags" do
      expect(highlighted).to eq("the <HIGHLIGHT>HIGHLIGHT</HIGHLIGHT> word")
    end
  end

  context "when a term contains regular-expression metacharacters" do
    let(:translation) { build_translation("costs 5$ (net) today") }

    before do
      create(:term, source_term: "5$", target_term: "5$", glossary: glossary)
      create(:term, source_term: "net", target_term: "net", glossary: glossary)
    end

    it "treats the term as a literal string" do
      expect(highlighted).to eq("costs <HIGHLIGHT>5$</HIGHLIGHT> (<HIGHLIGHT>net</HIGHLIGHT>) today")
    end
  end

  describe "the serialized payload" do
    let(:translation) { build_translation("This is a nat test") }

    before { create(:term, source_term: "is", target_term: "ist", glossary: glossary) }

    it "exposes the documented attributes" do
      payload = ActiveModelSerializers::SerializableResource.new(
        translation, serializer: described_class
      ).as_json

      expect(payload.keys).to match_array(%i[id source_language_code target_language_code source_text glossary_id])
      expect(payload[:source_text]).to eq("This <HIGHLIGHT>is</HIGHLIGHT> a nat test")
      expect(payload[:glossary_id]).to eq(glossary.id)
    end
  end
end
