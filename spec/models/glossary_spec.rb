require "rails_helper"

RSpec.describe Glossary, type: :model do
  let(:valid_attributes) do
    {
      source_language_code: "en",
      target_language_code: "es"
    }
  end

  describe "associations" do
    it { should have_many(:terms).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:source_language_code) }
    it { should validate_presence_of(:target_language_code) }
    it { should validate_inclusion_of(:source_language_code).in_array(Glossary::ISO_639_1_CODES) }
    it { should validate_inclusion_of(:target_language_code).in_array(Glossary::ISO_639_1_CODES) }

    it "validates the uniqueness of the source and target language codes" do
      Glossary.create!(valid_attributes)
      duplicate_glossary = Glossary.new(valid_attributes)
      expect(duplicate_glossary).not_to be_valid
      expect(duplicate_glossary.errors[:source_language_code]).to include("has already been taken")
    end
  end
end
