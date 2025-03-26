#!/bin/bash
set -euo pipefail

# Remove a stale pidfile left by a container that did not shut down cleanly.
rm -f /app/tmp/pids/server.pid

# db:prepare creates the database and loads db/schema.rb the first time, and
# applies pending migrations on every subsequent boot. Both are idempotent, as
# is db/seeds.rb, so the app is never empty on first boot and never duplicated
# on the next one.
if [ "${SKIP_DB_SETUP:-}" != "1" ]; then
  bundle exec rails db:prepare
  bundle exec rails db:seed
fi

exec "$@"
