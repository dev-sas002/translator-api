class TermsController < ApplicationController
  def create
    # `find` (not `find_by`) so a missing glossary is turned into the shared
    # 404 payload by ApplicationController rather than a nil check here.
    glossary = Glossary.find(params[:glossary_id])
    term = glossary.terms.build(term_params)

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
end
