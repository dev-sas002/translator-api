require "rails_helper"

RSpec.describe "Health", type: :request do
  it "reports ok when the database answers" do
    get "/health"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include("status" => "ok", "database" => "ok")
  end

  it "advertises the registered markup styles and matching strategies" do
    get "/health"

    expect(response.parsed_body["markup_styles"]).to include("highlight", "mark", "brackets")
    expect(response.parsed_body["matching_strategies"]).to include("automaton", "regexp")
  end

  it "reports 503 when the database is unreachable" do
    allow(ActiveRecord::Base).to receive(:connection).and_raise(ActiveRecord::ConnectionNotEstablished)

    get "/health"

    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body).to include("status" => "degraded", "database" => "unavailable")
  end

  it "is not throttled", :rate_limited do
    200.times { get "/health" }

    expect(response).to have_http_status(:ok)
  end
end
