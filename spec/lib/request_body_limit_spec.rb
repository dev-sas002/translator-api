require "rails_helper"

RSpec.describe RequestBodyLimit do
  let(:downstream) do
    lambda do |env|
      body = env["rack.input"].read
      [200, {"Content-Type" => "text/plain"}, [body.bytesize.to_s]]
    end
  end

  subject(:middleware) { described_class.new(downstream, limit: 16) }

  def env_for(body, content_length: body.bytesize)
    {
      "REQUEST_METHOD" => "POST",
      "PATH_INFO" => "/translations",
      "CONTENT_LENGTH" => content_length&.to_s,
      "rack.input" => StringIO.new(body)
    }.compact
  end

  it "passes a body under the limit through" do
    status, _headers, body = middleware.call(env_for("hello"))

    expect(status).to eq(200)
    expect(body).to eq(["5"])
  end

  it "passes a body exactly at the limit through" do
    status, = middleware.call(env_for("a" * 16))

    expect(status).to eq(200)
  end

  it "rejects on Content-Length without calling the app" do
    expect(downstream).not_to receive(:call)

    status, headers, body = middleware.call(env_for("a" * 17))

    expect(status).to eq(413)
    expect(headers["Content-Type"]).to eq("application/json")
    expect(JSON.parse(body.first)["errors"]).to eq("Request body too large (limit 16 bytes)")
  end

  # A chunked request arrives with no Content-Length at all, so the header
  # check cannot see it coming; the wrapped input is what stops it.
  it "rejects a chunked body that exceeds the limit mid-stream" do
    status, _headers, body = middleware.call(env_for("a" * 64, content_length: nil))

    expect(status).to eq(413)
    expect(JSON.parse(body.first)["errors"]).to match(/too large/)
  end

  it "allows a chunked body under the limit" do
    status, _headers, body = middleware.call(env_for("hello", content_length: nil))

    expect(status).to eq(200)
    expect(body).to eq(["5"])
  end

  it "counts bytes across successive reads" do
    reader = lambda do |env|
      input = env["rack.input"]
      8.times { input.read(4) }
      [200, {}, []]
    end

    status, = described_class.new(reader, limit: 16).call(env_for("a" * 32, content_length: nil))

    expect(status).to eq(413)
  end

  it "counts bytes in a line-oriented read" do
    reader = ->(env) { [200, {}, [env["rack.input"].gets.to_s]] }

    status, = described_class.new(reader, limit: 4).call(env_for("hello world", content_length: nil))

    expect(status).to eq(413)
  end

  it "counts bytes when the body is iterated" do
    reader = ->(env) { env["rack.input"].each { |_chunk| nil } || [200, {}, []] }

    status, = described_class.new(reader, limit: 4).call(env_for("hello world", content_length: nil))

    expect(status).to eq(413)
  end

  it "measures bytes rather than characters" do
    # Four multi-byte characters: 4 characters, 12 bytes.
    status, = described_class.new(downstream, limit: 8).call(env_for("日本語だ", content_length: nil))

    expect(status).to eq(413)
  end

  it "resets its counter on rewind" do
    reader = lambda do |env|
      input = env["rack.input"]
      input.read
      input.rewind
      [200, {}, [input.read]]
    end

    status, _headers, body = described_class.new(reader, limit: 16).call(env_for("hello", content_length: nil))

    expect(status).to eq(200)
    expect(body).to eq(["hello"])
  end

  it "leaves a request with no body alone" do
    env = {"REQUEST_METHOD" => "GET", "PATH_INFO" => "/health"}

    status, = described_class.new(->(_env) { [200, {}, []] }, limit: 16).call(env)

    expect(status).to eq(200)
  end
end
