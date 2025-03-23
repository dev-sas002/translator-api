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
end
