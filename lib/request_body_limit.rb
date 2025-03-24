# Rejects oversized request bodies before Rails parses them.
#
# `source_text` is capped at 5000 characters by a model validation, but that
# validation only runs after Rack has buffered and JSON-parsed the whole
# body. A 200 MB POST would therefore be read into memory in full before
# being rejected. This middleware answers 413 from the Content-Length header,
# and also stops a request that lies about its length mid-stream.
class RequestBodyLimit
  DEFAULT_LIMIT = 1_048_576 # 1 MiB

  def initialize(app, limit: DEFAULT_LIMIT)
    @app = app
    @limit = limit
  end

  def call(env)
    declared = env["CONTENT_LENGTH"].to_i
    return too_large if declared > @limit

    env["rack.input"] = BoundedInput.new(env["rack.input"], @limit) if env["rack.input"]

    @app.call(env)
  rescue BodyTooLarge
    too_large
  end

  private

  def too_large
    body = {errors: "Request body too large (limit #{@limit} bytes)"}.to_json
    [413, {"Content-Type" => "application/json", "Content-Length" => body.bytesize.to_s}, [body]]
  end

  class BodyTooLarge < StandardError; end

  # Wraps rack.input and raises once more than `limit` bytes have been read,
  # so a chunked or mis-declared body cannot slip past the header check.
  class BoundedInput
    def initialize(io, limit)
      @io = io
      @limit = limit
      @read = 0
    end

    def read(*args)
      track(@io.read(*args))
    end

    def gets(*args)
      track(@io.gets(*args))
    end

    def each
      @io.each { |chunk| yield track(chunk) }
    end

    def rewind
      @read = 0
      @io.rewind
    end

    def size
      @io.respond_to?(:size) ? @io.size : nil
    end

    def close
      @io.close if @io.respond_to?(:close)
    end

    private

    def track(chunk)
      return chunk if chunk.nil?

      @read += chunk.bytesize
      raise BodyTooLarge if @read > @limit

      chunk
    end
  end
end
