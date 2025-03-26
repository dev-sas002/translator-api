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
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns a JSON response with errors" do
        expect(response.content_type).to include("application/json")
        expect(response.parsed_body).to include("source_language_code", "target_language_code")
      end

      it "does not persist anything" do
        expect(Glossary.count).to eq(0)
      end
    end

    context "when a language code is not an ISO 639-1 code" do
      it "returns 422" do
        expect {
          post "/glossaries", params: {glossary: {source_language_code: "zz", target_language_code: "en"}}
        }.not_to change(Glossary, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body).to include("source_language_code")
      end
    end

    context "when the language pair already exists" do
      before { create(:glossary, source_language_code: "en", target_language_code: "fr") }

      it "returns 422 rather than creating a duplicate" do
        expect {
          post "/glossaries", params: {glossary: {source_language_code: "en", target_language_code: "fr"}}
        }.not_to change(Glossary, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["source_language_code"]).to include("has already been taken")
      end

      it "allows the same source language with a different target language" do
        expect {
          post "/glossaries", params: {glossary: {source_language_code: "en", target_language_code: "de"}}
        }.to change(Glossary, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end

    context "when the glossary key is missing entirely" do
      it "returns 400 Bad Request" do
        post "/glossaries", params: {source_language_code: "en"}

        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body["errors"]).to eq("Required parameter missing: glossary")
      end
    end
  end

  describe "POST #create case sensitivity" do
    it "defaults to case sensitive" do
      post "/glossaries", params: {glossary: {source_language_code: "en", target_language_code: "fr"}}

      expect(response.parsed_body["case_sensitive"]).to be(true)
      expect(Glossary.last).to be_case_sensitive
    end

    it "accepts a case-insensitive glossary" do
      post "/glossaries", params: {glossary: {
        source_language_code: "en", target_language_code: "fr", case_sensitive: false
      }}

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["case_sensitive"]).to be(false)
      expect(Glossary.last).not_to be_case_sensitive
    end
  end

  describe "GET #index" do
    it "returns an empty array when there are no glossaries" do
      get "/glossaries"
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq([])
    end

    it "returns every glossary with its nested terms" do
      glossary = create(:glossary, source_language_code: "en", target_language_code: "fr")
      create(:term, source_term: "cat", target_term: "chat", glossary: glossary)
      create(:glossary, source_language_code: "en", target_language_code: "de")

      get "/glossaries"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body.size).to eq(2)

      serialized = body.find { |entry| entry["id"] == glossary.id }
      expect(serialized["source_language_code"]).to eq("en")
      expect(serialized["target_language_code"]).to eq("fr")
      expect(serialized["terms"].map { |term| term["source_term"] }).to eq(["cat"])
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

      it "returns 404 for a non-numeric id rather than raising" do
        get "/glossaries/not-an-id"
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the glossary has terms" do
      it "includes them in the payload" do
        create(:term, source_term: "cat", target_term: "chat", glossary: glossary)

        get "/glossaries/#{glossary.id}"

        terms = response.parsed_body["terms"]
        expect(terms.size).to eq(1)
        expect(terms.first).to include("source_term" => "cat", "target_term" => "chat")
      end
    end
  end
end
