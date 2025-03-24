require_relative "boot"

# This is an API-only application: it serves JSON over HTTP and nothing else.
# Requiring the individual railties instead of `rails/all` keeps Action Mailer,
# Action Cable, Active Storage, Action Text, Action Mailbox and Sprockets out
# of the process entirely — less boot time, less memory, and a smaller surface
# to secure.
require "rails"
require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"

require_relative "../lib/request_body_limit"

# Require the gems listed in Gemfile, including any gems you've limited to
# :test, :development, or :production.
Bundler.require(*Rails.groups)

module TranslatorApi
  class Application < Rails::Application
    config.load_defaults 7.0

    # Loads a smaller middleware stack suitable for API-only apps: no session,
    # flash, cookies or view rendering.
    config.api_only = true

    # `app/domain` needs no registration: every app/* directory is an
    # autoload root, so Highlighting::* resolves from app/domain/highlighting.

    # Reject oversized bodies before Rack buffers them (see the middleware).
    config.middleware.insert_before 0, RequestBodyLimit,
      limit: Integer(ENV.fetch("MAX_REQUEST_BODY_BYTES", RequestBodyLimit::DEFAULT_LIMIT))

    # Uncaught exceptions render as JSON rather than HTML error pages.
    config.debug_exception_response_format = :api
  end
end
