require "rails_helper"

RSpec.describe "Glossaries", type: :request do
  describe "POST #create" do
    context "when the request is valid" do
      let(:valid_attributes) { {glossary: {source_language_code: "en", target_language_code: "fr"}} }

      before { post "/glossaries", params: valid_attributes }

      it "creates a glossary" do
        expect(response).to have_http_status(:created)
      end

      it "returns a JSON response with the created glossary" do
        expect(response.content_type).to include("application/json")
        expect(response.body).to match(/"id":\d+/)
        expect(response.body).to match(/"source_language_code":"en"/)
        expect(response.body).to match(/"target_language_code":"fr"/)
      end
    end

    context "when the request is invalid" do
      let(:invalid_attributes) { {glossary: {source_language_code: "", target_language_code: ""}} }

      before { post "/glossaries", params: invalid_attributes }

      it "returns a 422 response" do
        expect(response).to have_http_status(422)
      end

      it "returns a JSON response with errors" do
        expect(response.content_type).to include("application/json")
        expect(response.parsed_body).to include("source_language_code", "target_language_code")
      end
    end
  end

  describe "GET #index" do
    before { get "/glossaries" }

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "JSON body response contains expected glossaries" do
      json_response = JSON.parse(response.body)
      expect(json_response.size).to eq(Glossary.all.count)
    end
  end

  describe "GET #show" do
    let(:glossary) { create(:glossary) }

    it "returns status ok" do
      get "/glossaries/#{glossary.id}"
      expect(response).to have_http_status(:ok)
    end

    context "when glossary exists" do
      it "returns the glossary in JSON format" do
        get "/glossaries/#{glossary.id}"
        expect(response.parsed_body["id"]).to eq(glossary.id)
        expect(response.parsed_body["source_language_code"]).to eq(glossary.source_language_code)
        expect(response.parsed_body["target_language_code"]).to eq(glossary.target_language_code)
      end
    end

    context "when glossary does not exist" do
      it "returns status code 404" do
        get "/glossaries/999"
        expect(response).to have_http_status(:not_found)
      end

      it "returns an error message in JSON format" do
        get "/glossaries/999"
        expect(response.parsed_body["errors"]).to eq("Glossary not found")
      end
    end
  end
end
