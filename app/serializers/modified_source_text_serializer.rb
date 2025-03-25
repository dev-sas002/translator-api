# Renders a translation with its glossary terms marked up.
#
# The serializer holds no matching logic of its own: it delegates to
# Highlighting::GlossaryHighlighter, which is where the behaviour is specified
# and tested. The markup style is passed through from the controller.
class ModifiedSourceTextSerializer < ActiveModel::Serializer
  attributes :id, :source_language_code, :target_language_code, :source_text, :glossary_id

  def source_text
    Highlighting::GlossaryHighlighter.call(object, markup: markup)
  end

  private

  def markup
    instance_options[:markup] || Highlighting::Markup::DEFAULT
  end
end
