require "rails_helper"

RSpec.describe "Pagination", type: :request do
  # Thirty distinct language pairs, so the default page size of 25 is exceeded.
  def create_glossaries(count)
    pairs = Glossary::ISO_639_1_CODES.first(count)
    pairs.map { |code| create(:glossary, source_language_code: "en", target_language_code: code) }
  end

  it "returns the whole collection when it fits on one page" do
    create_glossaries(3)

    get "/glossaries"

    expect(response.parsed_body.size).to eq(3)
    expect(response.headers["X-Total-Count"]).to eq("3")
    expect(response.headers["X-Total-Pages"]).to eq("1")
  end

  it "caps an unpaginated request at the default page size" do
    create_glossaries(30)

    get "/glossaries"

    expect(response.parsed_body.size).to eq(Paginated::DEFAULT_PER_PAGE)
    expect(response.headers["X-Total-Count"]).to eq("30")
    expect(response.headers["X-Page"]).to eq("1")
    expect(response.headers["X-Total-Pages"]).to eq("2")
  end

  it "returns the requested page" do
    create_glossaries(30)

    get "/glossaries", params: {page: 2}

    expect(response.parsed_body.size).to eq(5)
    expect(response.headers["X-Page"]).to eq("2")
  end

  it "returns disjoint, ordered pages that cover the collection" do
    glossaries = create_glossaries(30)

    get "/glossaries", params: {page: 1, per_page: 10}
    first = response.parsed_body.map { |entry| entry["id"] }
    get "/glossaries", params: {page: 2, per_page: 10}
    second = response.parsed_body.map { |entry| entry["id"] }
    get "/glossaries", params: {page: 3, per_page: 10}
    third = response.parsed_body.map { |entry| entry["id"] }

    expect(first + second + third).to eq(glossaries.map(&:id).sort)
  end

  it "honours per_page" do
    create_glossaries(30)

    get "/glossaries", params: {per_page: 4}

    expect(response.parsed_body.size).to eq(4)
    expect(response.headers["X-Total-Pages"]).to eq("8")
  end

  it "clamps per_page to the maximum so a client cannot ask for everything" do
    create_glossaries(30)

    get "/glossaries", params: {per_page: 100_000}

    expect(response.headers["X-Per-Page"]).to eq(Paginated::MAX_PER_PAGE.to_s)
  end

  it "treats a non-positive or unparseable page as the first page" do
    create_glossaries(30)

    ["0", "-3", "not-a-number"].each do |page|
      get "/glossaries", params: {page: page}
      expect(response.headers["X-Page"]).to eq("1")
    end
  end

  it "falls back to the default when per_page is unparseable" do
    create_glossaries(3)

    get "/glossaries", params: {per_page: "lots"}

    expect(response.headers["X-Per-Page"]).to eq(Paginated::DEFAULT_PER_PAGE.to_s)
  end

  it "returns an empty page past the end rather than an error" do
    create_glossaries(3)

    get "/glossaries", params: {page: 99}

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq([])
  end

  it "reports one total page for an empty collection" do
    get "/glossaries"

    expect(response.headers["X-Total-Count"]).to eq("0")
    expect(response.headers["X-Total-Pages"]).to eq("1")
  end
end
