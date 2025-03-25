class GlossariesController < ApplicationController
  include Paginated

  def index
    render json: paginate(Glossary.ordered.with_terms)
  end

  def show
    render json: Glossary.with_terms.find(params[:id])
  end

  def create
    glossary = Glossary.new(glossary_params)

    if glossary.save
      render json: glossary, status: :created
    else
      render json: glossary.errors, status: :unprocessable_entity
    end
  end

  private

  def glossary_params
    params.require(:glossary).permit(:source_language_code, :target_language_code, :case_sensitive)
  end
end
