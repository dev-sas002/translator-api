# Rack::Attack is disabled in the test environment (see
# config/initializers/rack_attack.rb) so the suite is not throttled by its own
# volume. Tag an example `:rate_limited` to turn it on for that example only,
# with a counter store that starts empty.
RSpec.configure do |config|
  config.around(:each, :rate_limited) do |example|
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.enabled = true
    begin
      example.run
    ensure
      Rack::Attack.enabled = false
    end
  end
end
