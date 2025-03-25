class ApplicationController < ActionController::API
  # Error handling lives here so every endpoint returns the same JSON shape for
  # the same class of failure, and so controller actions can use `find` and
  # `require` without defensive branching.
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::ParameterMissing, with: :render_parameter_missing
  rescue_from Highlighting::Markup::Unknown, with: :render_unprocessable

  private

  # `exception.model` is the class name Rails was looking for, which gives
  # "Glossary not found" / "Translation not found" without repeating the string
  # in each controller.
  def render_not_found(exception)
    render json: {errors: "#{exception.model || "Record"} not found"}, status: :not_found
  end

  def render_parameter_missing(exception)
    render json: {errors: "Required parameter missing: #{exception.param}"}, status: :bad_request
  end

  def render_unprocessable(exception)
    render json: {errors: exception.message}, status: :unprocessable_entity
  end
end
