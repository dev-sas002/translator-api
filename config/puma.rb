# Puma serves each request in a thread from a pool. The maximum is kept in step
# with the Active Record connection pool (config/database.yml reads the same
# variable), so a saturated web server cannot starve itself of connections.
max_threads_count = ENV.fetch("RAILS_MAX_THREADS", 5)
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

# Long waits are tolerable while debugging, not in production.
worker_timeout 3600 if ENV.fetch("RAILS_ENV", "development") == "development"

port ENV.fetch("PORT", 3000)
environment ENV.fetch("RAILS_ENV", "development")
pidfile ENV.fetch("PIDFILE", "tmp/pids/server.pid")

# Forked workers multiply throughput on a multi-core host. Left at one by
# default because Highlighting::MatcherCache and the Rack::Attack counters are
# per-process (see the README's Limitations).
workers ENV.fetch("WEB_CONCURRENCY", 0).to_i
preload_app! if ENV.fetch("WEB_CONCURRENCY", 0).to_i.positive?

plugin :tmp_restart
