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
        expect(response).to have_http_status(422)
      end

      it "returns a JSON response with errors" do
        expect(response.content_type).to include("application/json")
        expect(response.parsed_body).to include("source_term", "target_term")
      end
    end
  end
end
