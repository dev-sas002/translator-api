class GlossariesController < ApplicationController
  def create
    glossary = Glossary.new(glossary_params)

    if glossary.save
      render json: glossary, status: :created
    else
      render json: glossary.errors, status: :unprocessable_entity
    end
  end

  def show
    glossary = Glossary.find_by(id: params[:id])
    if glossary.present?
      render json: glossary
    else
      render json: {errors: "Glossary not found"}, status: 404
    end
  end

  def index
    glossaries = Glossary.all.includes(:terms)
    render json: glossaries
  end

  private

  def glossary_params
    params.require(:glossary).permit(:source_language_code, :target_language_code)
  end
end
