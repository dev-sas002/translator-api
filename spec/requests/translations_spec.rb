require "rails_helper"
require "net/http"

RSpec.describe "Translations", type: :request do
  describe "POST #create" do
    context "when the request is valid" do
      let(:glossary) { create(:glossary) }
      let(:valid_attributes) do
        {translation: {
          source_language_code: glossary.source_language_code,
          target_language_code: glossary.target_language_code,
          source_text: "this is source text",
          glossary_id: glossary.id
        }}
      end

      it "creates a translation with a glossary_id" do
        expect { post("/translations", params: valid_attributes) }
          .to change(Translation, :count).by(1)
        expect(response).to have_http_status(:created)
      end

      it "creates a translation without a glossary_id" do
        valid_attributes[:translation].delete(:glossary_id)
        post("/translations", params: valid_attributes)
        expect(response).to have_http_status(:created)
        expect(Translation.last.glossary_id).to be_nil
      end

      it "returns the persisted translation as JSON" do
        post("/translations", params: valid_attributes)

        expect(response.content_type).to include("application/json")
        body = response.parsed_body
        expect(body["id"]).to eq(Translation.last.id)
        expect(body["source_language_code"]).to eq(glossary.source_language_code)
        expect(body["target_language_code"]).to eq(glossary.target_language_code)
        expect(body["source_text"]).to eq("this is source text")
        expect(body["glossary_id"]).to eq(glossary.id)
      end

      it "ignores attributes that are not permitted" do
        post("/translations", params: {translation: valid_attributes[:translation].merge(id: 424242)})

        expect(response).to have_http_status(:created)
        expect(Translation.find_by(id: 424242)).to be_nil
      end
    end

    context "when the request is invalid" do
      let(:invalid_attributes) { {translation: {source_language_code: "", target_language_code: "", source_text: ""}} }

      before { post "/translations", params: invalid_attributes }

      it "returns a 422 response" do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns a JSON response with errors" do
        expect(response.content_type).to include("application/json")
        expect(response.parsed_body).to include("source_language_code", "target_language_code", "source_text")
      end
    end

    context "when the language codes are not ISO 639-1 codes" do
      it "returns 422 and does not persist anything" do
        expect {
          post "/translations", params: {translation: {
            source_language_code: "zz", target_language_code: "qq", source_text: "hello"
          }}
        }.not_to change(Translation, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body).to include("source_language_code", "target_language_code")
      end
    end

    context "when source_text exceeds the 5000 character limit" do
      it "returns 422" do
        post "/translations", params: {translation: {
          source_language_code: "en", target_language_code: "fr", source_text: "a" * 5001
        }}

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body).to include("source_text")
      end

      it "accepts exactly 5000 characters" do
        post "/translations", params: {translation: {
          source_language_code: "en", target_language_code: "fr", source_text: "a" * 5000
        }}

        expect(response).to have_http_status(:created)
      end
    end

    context "when glossary_id refers to a glossary that does not exist" do
      it "returns 422 instead of persisting a dangling reference" do
        expect {
          post "/translations", params: {translation: {
            source_language_code: "en",
            target_language_code: "fr",
            source_text: "hello",
            glossary_id: 999_999
          }}
        }.not_to change(Translation, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["glossary"]).to include("must exist")
      end
    end

    context "when the glossary language codes do not match the request" do
      let(:glossary) { create(:glossary, source_language_code: "en", target_language_code: "fr") }

      it "returns 422" do
        post "/translations", params: {translation: {
          source_language_code: "de",
          target_language_code: "fr",
          source_text: "hello",
          glossary_id: glossary.id
        }}

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["glossary"])
          .to include("language codes do not match with the source and target language codes")
      end
    end

    context "when the translation key is missing entirely" do
      it "returns 400 Bad Request" do
        post "/translations", params: {source_text: "hello"}

        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body["errors"]).to eq("Required parameter missing: translation")
      end

      # Parameter wrapping is disabled (config/initializers/wrap_parameters.rb)
      # so a JSON body is held to the same contract as a form-encoded one
      # rather than being silently rewrapped under the expected key.
      it "returns 400 Bad Request for a JSON body too" do
        post "/translations",
          params: {source_text: "hello"}.to_json,
          headers: {"CONTENT_TYPE" => "application/json"}

        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body["errors"]).to eq("Required parameter missing: translation")
      end

      it "accepts a correctly wrapped JSON body" do
        post "/translations",
          params: {translation: {
            source_language_code: "en", target_language_code: "fr", source_text: "hello"
          }}.to_json,
          headers: {"CONTENT_TYPE" => "application/json"}

        expect(response).to have_http_status(:created)
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

      it "returns the same body when requested twice" do
        get "/translations/#{translation.id}"
        first = response.body
        get "/translations/#{translation.id}"
        expect(response.body).to eq(first)
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

      it "returns 404 for a non-numeric id rather than raising" do
        get "/translations/not-an-id"
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET #show markup selection" do
    let(:glossary) { create(:glossary, source_language_code: "en", target_language_code: "fr") }
    let(:translation) do
      create(:translation, source_language_code: "en", target_language_code: "fr",
        source_text: "the cat sat", glossary: glossary)
    end

    before { create(:term, source_term: "cat", target_term: "chat", glossary: glossary) }

    it "uses <HIGHLIGHT> markers by default" do
      get "/translations/#{translation.id}"

      expect(response.parsed_body["source_text"]).to eq("the <HIGHLIGHT>cat</HIGHLIGHT> sat")
    end

    it "renders a registered markup style on request" do
      get "/translations/#{translation.id}", params: {markup: "mark"}

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["source_text"]).to eq("the <mark>cat</mark> sat")
    end

    it "renders the bracket style on request" do
      get "/translations/#{translation.id}", params: {markup: "brackets"}

      expect(response.parsed_body["source_text"]).to eq("the [[cat]] sat")
    end

    it "returns 422 listing the registered styles for an unknown one" do
      get "/translations/#{translation.id}", params: {markup: "neon"}

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).to match(/unknown markup.*highlight.*mark.*brackets/m)
    end

    it "does not alter the stored text whichever style is used" do
      get "/translations/#{translation.id}", params: {markup: "mark"}

      expect(translation.reload.source_text).to eq("the cat sat")
    end
  end

  describe "GET #show with a case-insensitive glossary" do
    let(:glossary) do
      create(:glossary, source_language_code: "en", target_language_code: "fr", case_sensitive: false)
    end
    let(:translation) do
      create(:translation, source_language_code: "en", target_language_code: "fr",
        source_text: "The Cat sat", glossary: glossary)
    end

    before { create(:term, source_term: "cat", target_term: "chat", glossary: glossary) }

    it "highlights regardless of case and preserves the original casing" do
      get "/translations/#{translation.id}"

      expect(response.parsed_body["source_text"]).to eq("The <HIGHLIGHT>Cat</HIGHLIGHT> sat")
    end
  end

  describe "upstream providers" do
    # This application performs no machine translation: `source_text` is stored
    # verbatim and glossary terms are highlighted locally (see
    # ModifiedSourceTextSerializer). There is therefore no provider client to
    # mock, and no request may reach the network. This guard fails loudly if a
    # future change introduces an unmocked outbound call.
    let(:glossary) { create(:glossary) }

    before do
      allow(Net::HTTP).to receive(:start).and_raise("unexpected outbound HTTP call in specs")
      allow(Net::HTTP).to receive(:new).and_raise("unexpected outbound HTTP call in specs")
    end

    it "does not make outbound HTTP calls while creating and reading a translation" do
      post "/translations", params: {translation: {
        source_language_code: glossary.source_language_code,
        target_language_code: glossary.target_language_code,
        source_text: "this is source text",
        glossary_id: glossary.id
      }}
      expect(response).to have_http_status(:created)

      get "/translations/#{response.parsed_body["id"]}"
      expect(response).to have_http_status(:ok)
    end
  end
end
