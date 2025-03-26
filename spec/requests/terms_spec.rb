require "rails_helper"

RSpec.describe "Terms", type: :request do
  describe "POST #create" do
    let(:glossary) { create(:glossary) }

    context "when the request is valid" do
      let(:valid_attributes) { {term: {source_term: "this", target_term: "this"}} }

      before { post "/glossaries/#{glossary.id}/terms", params: valid_attributes }

      it "creates a term" do
        expect(response).to have_http_status(:created)
      end

      it "returns a JSON response with the created term" do
        expect(response.content_type).to include("application/json")
        expect(response.body).to match(/"id":\d+/)
        expect(response.parsed_body["source_term"]).to eq("this")
        expect(response.parsed_body["target_term"]).to eq("this")
      end
    end

    context "when the request is invalid" do
      let(:invalid_attributes) { {term: {source_term: "", target_term: ""}} }

      before { post "/glossaries/#{glossary.id}/terms", params: invalid_attributes }

      it "returns a 422 response" do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns a JSON response with errors" do
        expect(response.content_type).to include("application/json")
        expect(response.parsed_body).to include("source_term", "target_term")
      end

      it "does not persist anything" do
        expect(Term.count).to eq(0)
      end
    end

    context "when the glossary does not exist" do
      it "returns 404 with a JSON error instead of raising" do
        expect {
          post "/glossaries/999999/terms", params: {term: {source_term: "cat", target_term: "chat"}}
        }.not_to change(Term, :count)

        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body["errors"]).to eq("Glossary not found")
      end
    end

    context "when the term key is missing entirely" do
      it "returns 400 Bad Request" do
        post "/glossaries/#{glossary.id}/terms", params: {source_term: "cat"}

        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body["errors"]).to eq("Required parameter missing: term")
      end
    end

    context "when the glossary already has terms" do
      it "appends rather than replacing" do
        create(:term, source_term: "cat", target_term: "chat", glossary: glossary)

        expect {
          post "/glossaries/#{glossary.id}/terms", params: {term: {source_term: "dog", target_term: "chien"}}
        }.to change { glossary.terms.count }.from(1).to(2)

        expect(response).to have_http_status(:created)
      end
    end

    it "only assigns permitted attributes" do
      other_glossary = create(:glossary, source_language_code: "en", target_language_code: "de")

      post "/glossaries/#{glossary.id}/terms",
        params: {term: {source_term: "cat", target_term: "chat", glossary_id: other_glossary.id}}

      expect(response).to have_http_status(:created)
      expect(Term.last.glossary_id).to eq(glossary.id)
    end
  end
end
