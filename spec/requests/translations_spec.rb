require "rails_helper"

RSpec.describe "Translations", type: :request do
  describe "POST #create" do
    context "when the request is valid" do
      let(:glossary) { create(:glossary) }
      let(:valid_attributes) { {translation: {source_language_code: glossary.source_language_code, target_language_code: glossary.target_language_code, source_text: "this is source text", glossary_id: glossary.id}} }

      it "creates a translation with grossary_id" do
        post("/translations", params: valid_attributes)
        expect(response).to have_http_status(:created)
      end

      it "creates a translation without grossary_id" do
        valid_attributes[:translation].delete(:glossary_id)
        post("/translations", params: valid_attributes)
        expect(response).to have_http_status(:created)
      end
    end

    context "when tche request is invalid" do
      let(:invalid_attributes) { {translation: {source_language_code: "", target_language_code: "", source_text: ""}} }

      before { post "/translations", params: invalid_attributes }

      it "returns a 422 response" do
        expect(response).to have_http_status(422)
      end

      it "returns a JSON response with errors" do
        expect(response.content_type).to include("application/json")
        expect(response.parsed_body).to include("source_language_code", "target_language_code", "source_text")
      end
    end
  end

  describe "GET #show" do
    let(:glossary) { create(:glossary) }
    let(:translation) { create(:translation, source_text: "This is a nat test", glossary: glossary) }
    let(:highlighted_text) { "This <HIGHLIGHT>is</HIGHLIGHT> <HIGHLIGHT>a</HIGHLIGHT> nat test" }

    before do
      create(:term, source_term: "is", glossary: glossary)
      create(:term, source_term: "a", glossary: glossary)
    end

    it "returns status ok" do
      get "/translations/#{translation.id}"
      expect(response).to have_http_status(:ok)
    end

    context "when translation exists" do
      it "returns the translation in JSON format with highlighted source_text when glossary_id present" do
        get "/translations/#{translation.id}"
        expect(response.parsed_body["source_text"]).to eq(highlighted_text)
      end

      it "returns the translation in JSON format with normal source_text when glossary_id absent" do
        translation.glossary_id = nil
        translation.save!
        get "/translations/#{translation.id}"
        expect(response.parsed_body["source_text"]).to eq("This is a nat test")
      end
    end

    context "when translation does not exist" do
      it "returns status code 404" do
        get "/translations/1000"
        expect(response).to have_http_status(:not_found)
      end

      it "returns an error message in JSON format" do
        get "/translations/1000"
        expect(response.parsed_body["errors"]).to eq("Translation not found")
      end
    end
  end
end
