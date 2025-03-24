class ModifiedSourceTextSerializer < ActiveModel::Serializer
  attributes :id, :source_language_code, :target_language_code, :source_text, :glossary_id

  def source_text
    return object.source_text unless object.glossary.present?

    # Avoid mutating `object.source_text` in-place. Serializers should be
    # side-effect free so repeated rendering (or other consumers) doesn't
    # depend on render order.
    highlighted = object.source_text.dup
    glossary_terms = object.glossary.terms.pluck(:source_term)

    glossary_terms.each do |term|
      highlighted = highlighted.gsub(
        /(?<!\w)#{Regexp.escape(term)}(?!\w)/,
        "<HIGHLIGHT>#{term}</HIGHLIGHT>"
      )
    end

    highlighted
  end
end
