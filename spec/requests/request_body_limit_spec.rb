require "rails_helper"

RSpec.describe "Request body limit", type: :request do
  let(:limit) { RequestBodyLimit::DEFAULT_LIMIT }

  def post_json(body, headers = {})
    post "/translations",
      params: body,
      headers: {"CONTENT_TYPE" => "application/json"}.merge(headers)
  end

  it "accepts a body under the limit" do
    post_json({translation: {
      source_language_code: "en", target_language_code: "fr", source_text: "hello"
    }}.to_json)

    expect(response).to have_http_status(:created)
  end

  it "rejects a body over the limit with 413 before parsing it" do
    oversized = {translation: {source_text: "a" * (limit + 1024)}}.to_json

    expect { post_json(oversized) }.not_to change(Translation, :count)

    expect(response).to have_http_status(:payload_too_large)
    expect(response.parsed_body["errors"]).to match(/Request body too large/)
  end

  it "answers with JSON" do
    post_json({translation: {source_text: "a" * (limit + 1024)}}.to_json)

    expect(response.headers["Content-Type"]).to include("application/json")
  end
end
