#!/bin/bash

set -e

# Run database setup instructions (including migrations)
rm -f /myapp/tmp/pids/server.pid
bundle exec rails db:create db:migrate
bundle exec rails db:migrate

# Start the Rails server
exec "$@"
