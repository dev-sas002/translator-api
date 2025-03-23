class TermsController < ApplicationController
  before_action :build_term, only: %i[create]

  def create
    term = build_term
    if term.save
      render json: term, status: :created
    else
      render json: term.errors, status: :unprocessable_entity
    end
  end

  private

  def term_params
    params.require(:term).permit(:source_term, :target_term)
  end

  def build_term
    glossary = Glossary.find(params[:glossary_id])
    glossary.terms.build(term_params)
  end
end
