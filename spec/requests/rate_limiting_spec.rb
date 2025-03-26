require "rails_helper"

RSpec.describe "Rate limiting", :rate_limited, type: :request do
  let(:read_limit) { Integer(ENV.fetch("RATE_LIMIT_READS_PER_MINUTE", 120)) }
  let(:write_limit) { Integer(ENV.fetch("RATE_LIMIT_WRITES_PER_MINUTE", 30)) }

  it "allows reads up to the limit" do
    read_limit.times { get "/glossaries" }

    expect(response).to have_http_status(:ok)
  end

  it "throttles reads past the limit" do
    (read_limit + 1).times { get "/glossaries" }

    expect(response).to have_http_status(:too_many_requests)
    expect(response.parsed_body["errors"]).to match(/Rate limit exceeded/)
    expect(response.headers["Retry-After"]).to eq("60")
  end

  it "throttles writes on a separate, tighter budget" do
    (write_limit + 1).times do
      post "/glossaries", params: {glossary: {source_language_code: "en", target_language_code: "fr"}}
    end

    expect(response).to have_http_status(:too_many_requests)
  end

  it "counts reads and writes independently" do
    write_limit.times do
      post "/glossaries", params: {glossary: {source_language_code: "en", target_language_code: "fr"}}
    end

    get "/glossaries"

    expect(response).to have_http_status(:ok)
  end

  it "does not throttle when disabled, which is the suite's default" do
    Rack::Attack.enabled = false

    (read_limit + 5).times { get "/glossaries" }

    expect(response).to have_http_status(:ok)
  end
end
