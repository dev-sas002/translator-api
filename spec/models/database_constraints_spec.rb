require "rails_helper"

# The model validations already cover these cases for anything that goes
# through ActiveRecord. These examples assert the database enforces them too,
# so a bulk import, a console session or a second process cannot write data the
# API would reject.
RSpec.describe "Database constraints" do
  describe "the unique index on the glossary language pair" do
    it "rejects a duplicate pair inserted behind the validations" do
      create(:glossary, source_language_code: "en", target_language_code: "fr")

      expect {
        Glossary.insert_all!([{
          source_language_code: "en",
          target_language_code: "fr",
          created_at: Time.current,
          updated_at: Time.current
        }])
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows the same source language with a different target" do
      create(:glossary, source_language_code: "en", target_language_code: "fr")

      expect {
        create(:glossary, source_language_code: "en", target_language_code: "de")
      }.to change(Glossary, :count).by(1)
    end
  end

  describe "the foreign key on translations.glossary_id" do
    it "rejects a dangling reference inserted behind the validations" do
      expect {
        Translation.insert_all!([{
          source_language_code: "en",
          target_language_code: "fr",
          source_text: "hello",
          glossary_id: 999_999,
          created_at: Time.current,
          updated_at: Time.current
        }])
      }.to raise_error(ActiveRecord::InvalidForeignKey)
    end

    it "nullifies the reference when the glossary is deleted" do
      glossary = create(:glossary, source_language_code: "en", target_language_code: "fr")
      translation = create(:translation, source_language_code: "en", target_language_code: "fr",
        glossary: glossary)

      glossary.destroy!

      expect(translation.reload.glossary_id).to be_nil
    end

    it "still allows a null glossary_id" do
      expect {
        create(:translation, source_language_code: "en", target_language_code: "fr", glossary: nil)
      }.to change(Translation, :count).by(1)
    end
  end

  describe "the foreign key on terms.glossary_id" do
    it "rejects a term whose glossary does not exist" do
      expect {
        Term.insert_all!([{
          source_term: "cat",
          target_term: "chat",
          glossary_id: 999_999,
          created_at: Time.current,
          updated_at: Time.current
        }])
      }.to raise_error(ActiveRecord::InvalidForeignKey)
    end
  end
end
