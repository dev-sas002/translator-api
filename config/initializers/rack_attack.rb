# Per-IP throttling. The API is unauthenticated (see the README's Limitations
# section), so the only subject available to throttle on is the client address.
#
# Disabled in the test environment by default so the suite is not rate limited
# by its own volume; `spec/requests/rate_limiting_spec.rb` enables it for the
# examples that assert on it.
Rack::Attack.enabled = !Rails.env.test?

# Rack::Attack needs a counter store. Rails.cache is a null store in this app's
# development and test environments, which would silently disable throttling,
# so give it a dedicated in-process store. A multi-process deployment should
# point this at a shared Redis or Memcached instance instead — the limit is
# otherwise applied per worker.
Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

read_limit = Integer(ENV.fetch("RATE_LIMIT_READS_PER_MINUTE", 120))
write_limit = Integer(ENV.fetch("RATE_LIMIT_WRITES_PER_MINUTE", 30))

# Health checks must stay answerable while the app is being hammered.
Rack::Attack.safelist("health check") do |request|
  request.path == "/health"
end

Rack::Attack.throttle("reads per ip", limit: read_limit, period: 1.minute) do |request|
  request.ip if request.get?
end

Rack::Attack.throttle("writes per ip", limit: write_limit, period: 1.minute) do |request|
  request.ip if request.post? || request.put? || request.patch? || request.delete?
end

Rack::Attack.throttled_responder = lambda do |request|
  match = request.env["rack.attack.match_data"] || {}
  retry_after = (match[:period] || 60).to_i

  [
    429,
    {"Content-Type" => "application/json", "Retry-After" => retry_after.to_s},
    [{errors: "Rate limit exceeded. Retry in #{retry_after} seconds."}.to_json]
  ]
end
