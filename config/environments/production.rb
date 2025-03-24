require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true

  config.consider_all_requests_local = false

  # Static files are normally served by the proxy in front of the app.
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  # Terminate TLS at the proxy but refuse plaintext at the app as well.
  config.force_ssl = ENV["RAILS_FORCE_SSL"].present?

  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info").to_sym
  config.log_tags = [:request_id]
  config.log_formatter = ::Logger::Formatter.new

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger = ActiveSupport::Logger.new($stdout)
    logger.formatter = config.log_formatter
    config.logger = ActiveSupport::TaggedLogging.new(logger)
  end

  config.i18n.fallbacks = true
  config.active_support.report_deprecations = false

  # Schema is checked in; migrations must not rewrite it on a production host.
  config.active_record.dump_schema_after_migration = false
end
