require "active_support/core_ext/integer/time"

# The test environment is scratch space: the database is wiped between runs.
Rails.application.configure do
  config.cache_classes = true

  # Eager load in CI so a constant that only resolves lazily still fails there.
  config.eager_load = ENV["CI"].present?

  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.cache_store = :null_store

  # Raise instead of rendering an error payload, so an unexpected exception
  # fails the example it happened in.
  config.action_dispatch.show_exceptions = false
  config.action_controller.allow_forgery_protection = false

  # db/schema.rb is dumped from PostgreSQL, which is what development and
  # production run. The test database is SQLite scratch space and must never
  # become the source of the checked-in schema.
  config.active_record.dump_schema_after_migration = false

  config.active_support.deprecation = :stderr
  config.active_support.disallowed_deprecation = :raise
  config.active_support.disallowed_deprecation_warnings = []
end
