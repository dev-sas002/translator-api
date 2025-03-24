require "rails_helper"

RSpec.describe Translation, type: :model do
  describe "associations" do
    it { should belong_to(:glossary).optional(true) }
  end

  describe "validations" do
    it { should validate_presence_of(:source_language_code) }
    it { should validate_presence_of(:target_language_code) }
    it { should validate_inclusion_of(:source_language_code).in_array(Glossary::ISO_639_1_CODES) }
    it { should validate_inclusion_of(:target_language_code).in_array(Glossary::ISO_639_1_CODES) }
    it { should validate_presence_of(:source_text) }
    it { should validate_length_of(:source_text).is_at_most(5000) }

    context "when glossary is present" do
      let(:glossary) { build(:glossary) }
      let(:translation) { build(:translation, glossary: glossary) }
      it "validates that the source and target language codes match the glossary" do
        translation.source_language_code = "fr"
        expect(translation).to be_invalid
        expect(translation.errors[:glossary]).to include("language codes do not match with the source and target language codes")
      end
    end

    context "when glossary is not present" do
      let(:translation) { build(:translation, glossary: nil) }
      it "does not validate the glossary" do
        translation.source_language_code = "fr"
        expect(translation).to be_valid
      end
    end
  end

  describe "serialization" do
    it "does not mutate source_text when computing highlighted output" do
      glossary = create(:glossary, source_language_code: "en", target_language_code: "fr")
      translation = create(:translation,
        source_language_code: "en",
        target_language_code: "fr",
        source_text: "This is a nat test",
        glossary: glossary
      )

      create(:term, source_term: "is", target_term: "is", glossary: glossary)
      create(:term, source_term: "a", target_term: "a", glossary: glossary)

      original = translation.source_text.dup

      serializer = ModifiedSourceTextSerializer.new(translation)
      highlighted = serializer.source_text

      expect(highlighted).to eq("This <HIGHLIGHT>is</HIGHLIGHT> <HIGHLIGHT>a</HIGHLIGHT> nat test")
      expect(translation.source_text).to eq(original)
    end

    it "returns original source_text when glossary is nil" do
      translation = create(:translation,
        source_language_code: "en",
        target_language_code: "fr",
        source_text: "This is a nat test",
        glossary: nil
      )

      original = translation.source_text.dup
      serializer = ModifiedSourceTextSerializer.new(translation)

      expect(serializer.source_text).to eq(original)
      expect(translation.source_text).to eq(original)
    end
  end
end
