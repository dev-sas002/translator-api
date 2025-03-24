require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Code is reloaded on every request.
  config.cache_classes = false
  config.eager_load = false

  # Show full error reports (rendered as JSON; see config.api_only).
  config.consider_all_requests_local = true
  config.server_timing = true

  # `rails dev:cache` toggles caching.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.cache_store = :memory_store
  else
    config.action_controller.perform_caching = false
    config.cache_store = :null_store
  end

  config.active_support.deprecation = :log
  config.active_support.disallowed_deprecation = :raise
  config.active_support.disallowed_deprecation_warnings = []

  # Fail the request if migrations are pending rather than serving stale data.
  config.active_record.migration_error = :page_load
  config.active_record.verbose_query_logs = true
end
