# Counts the SQL statements a block issues, so N+1 regressions fail a test
# instead of being noticed in production.
module QueryCounter
  IGNORED = %w[SCHEMA TRANSACTION].freeze

  def count_queries
    queries = []

    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      next if IGNORED.include?(payload[:name]) || payload[:sql].start_with?("PRAGMA")
      queries << payload[:sql]
    end

    begin
      yield
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    queries
  end
end

RSpec.configure { |config| config.include QueryCounter }
