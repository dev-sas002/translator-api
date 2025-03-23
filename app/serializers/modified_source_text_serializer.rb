class ModifiedSourceTextSerializer < ActiveModel::Serializer
  attributes :id, :source_language_code, :target_language_code, :source_text, :glossary_id

  def source_text
    if object.glossary.present?
      glossary_terms = object.glossary.terms.pluck(:source_term)
      glossary_terms.each do |term|
        object.source_text.gsub!(/(?<!\w)#{Regexp.escape(term)}(?!\w)/, "<HIGHLIGHT>#{term}</HIGHLIGHT>")
      end
    end

    object.source_text
  end
end
