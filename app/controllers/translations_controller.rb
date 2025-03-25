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
    # The glossary and its terms are loaded lazily on purpose. Terms are only
    # read when Highlighting::MatcherCache misses, so a warm cache serves this
    # endpoint in two queries regardless of glossary size; eager loading would
    # make it three every time. The term lookup is covered by
    # index_terms_on_glossary_id_and_source_term.
    translation = Translation.find(params[:id])

    render json: translation,
      serializer: ModifiedSourceTextSerializer,
      markup: markup_param
  end

  private

  # Raises Highlighting::Markup::Unknown for an unregistered style, which
  # ApplicationController turns into a 422 listing the registered ones.
  def markup_param
    Highlighting::Markup.fetch(params[:markup]).name
  end

  def translation_params
    params.require(:translation).permit(:source_language_code, :target_language_code, :source_text, :glossary_id)
  end
end
