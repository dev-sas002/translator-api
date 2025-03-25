# Keeps index endpoints bounded.
#
# Collections are returned as a plain JSON array — the shape clients already
# depend on — and the paging metadata travels in response headers, so adding
# pagination did not change any existing response body.
module Paginated
  extend ActiveSupport::Concern

  DEFAULT_PER_PAGE = 25
  MAX_PER_PAGE = 100

  private

  # @param scope [ActiveRecord::Relation]
  # @return [ActiveRecord::Relation] limited to the requested page
  def paginate(scope)
    total = scope.count(:all)
    total_pages = [(total.to_f / per_page).ceil, 1].max

    response.set_header("X-Page", current_page.to_s)
    response.set_header("X-Per-Page", per_page.to_s)
    response.set_header("X-Total-Count", total.to_s)
    response.set_header("X-Total-Pages", total_pages.to_s)

    scope.limit(per_page).offset((current_page - 1) * per_page)
  end

  def current_page
    @current_page ||= [params[:page].to_i, 1].max
  end

  def per_page
    @per_page ||= begin
      requested = params[:per_page].to_i
      requested = DEFAULT_PER_PAGE if requested < 1
      [requested, MAX_PER_PAGE].min
    end
  end
end
