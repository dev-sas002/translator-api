class TranslationsController < ApplicationController
  def create
    translation = Translation.new(translation_params)
    if translation.save
      render json: translation, status: :created
    else
      render json: translation.errors, status: :unprocessable_entity
    end
  end

  def show
    translation = Translation.find_by(id: params[:id])
    if translation.present?
      render json: translation, serializer: ModifiedSourceTextSerializer
    else
      render json: {errors: "Translation not found"}, status: :not_found
    end
  end

  private

  def translation_params
    params.require(:translation).permit(:source_language_code, :target_language_code, :source_text, :glossary_id)
  end
end
