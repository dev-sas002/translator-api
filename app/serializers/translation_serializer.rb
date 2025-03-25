class TranslationSerializer < ActiveModel::Serializer
  attributes :id, :source_language_code, :target_language_code, :source_text, :glossary_id
end
