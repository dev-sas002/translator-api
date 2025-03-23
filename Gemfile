source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.1.3"

gem "rails", "~> 7.0.4", ">= 7.0.4.3"

# PostgreSQL for development and production (the test suite uses SQLite; see
# config/database.yml).
gem "pg", "~> 1.1"

gem "puma", "~> 5.0"

# JSON serialization for the API responses.
gem "active_model_serializers"

# Per-IP request throttling (config/initializers/rack_attack.rb).
gem "rack-attack", "~> 6.6"

# Windows does not ship zoneinfo files.
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]

# Reduces boot times through caching; required in config/boot.rb.
gem "bootsnap", require: false

group :development, :test do
  gem "debug", platforms: %i[mri mingw x64_mingw]
  gem "rspec-rails", "~> 6.0.0"
  gem "factory_bot_rails"
  gem "faker"
  # Required by spec/spec_helper.rb, so it must be available in the test group
  # too (a `bundle install --without development` would otherwise break rspec).
  gem "shoulda-matchers"
  # Linter and formatter. Kept out of :development only for the same reason.
  gem "standard", "~> 1.31"
  # SQLite for the test environment so the suite runs without an external
  # Postgres instance. ActiveRecord's sqlite adapter depends on
  # `sqlite3 (~> 1.4)`, so we pin to a compatible version.
  gem "sqlite3", "~> 1.4"
end

group :development do
  # Keeps the schema comments at the top of app/models/*.rb in sync.
  gem "annotate", "~> 3.2"
end
