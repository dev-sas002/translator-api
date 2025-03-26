# syntax=docker/dockerfile:1

# ---------------------------------------------------------------- build stage
# Compiles native extensions (pg, sqlite3, bootsnap) and resolves the bundle.
# None of this tooling reaches the runtime image.
FROM ruby:3.1.3-slim AS builder

ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_WITHOUT=development:test

RUN apt-get update -qq \
 && apt-get install --no-install-recommends -y build-essential libpq-dev \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install \
 && rm -rf "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY . .

# Precompile the bootsnap cache so the first request does not pay for it.
RUN bundle exec bootsnap precompile --gemfile app/ config/ lib/

# -------------------------------------------------------------- runtime stage
FROM ruby:3.1.3-slim AS runtime

ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_WITHOUT=development:test \
    RAILS_ENV=production \
    RAILS_LOG_TO_STDOUT=1 \
    PORT=3000

# libpq5 is the Postgres client library; curl is used by the healthcheck.
RUN apt-get update -qq \
 && apt-get install --no-install-recommends -y libpq5 curl tzdata \
 && rm -rf /var/lib/apt/lists/*

RUN groupadd --system --gid 1000 rails \
 && useradd --system --uid 1000 --gid rails --create-home rails

WORKDIR /app

COPY --from=builder --chown=rails:rails "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=builder --chown=rails:rails /app /app

# tmp/ must be writable by the app user: Puma writes its pidfile there.
RUN mkdir -p tmp/pids log && chown -R rails:rails tmp log

USER rails

EXPOSE 3000

HEALTHCHECK --interval=15s --timeout=5s --start-period=30s --retries=5 \
  CMD curl --fail --silent "http://127.0.0.1:${PORT}/health" || exit 1

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
