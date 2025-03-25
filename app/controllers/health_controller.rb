# Liveness/readiness probe. Used by the container healthcheck and exempt from
# rate limiting, so it stays answerable when the app is being hammered.
class HealthController < ApplicationController
  def show
    render json: {
      status: database_ok? ? "ok" : "degraded",
      database: database_ok? ? "ok" : "unavailable",
      markup_styles: Highlighting::Markup.names,
      matching_strategies: Highlighting.strategy_names
    }, status: database_ok? ? :ok : :service_unavailable
  end

  private

  def database_ok?
    return @database_ok unless @database_ok.nil?

    @database_ok = begin
      ActiveRecord::Base.connection.select_value("SELECT 1").to_i == 1
    rescue
      false
    end
  end
end
