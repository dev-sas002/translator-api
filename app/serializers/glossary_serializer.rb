class GlossarySerializer < ActiveModel::Serializer
  attributes :id, :source_language_code, :target_language_code, :case_sensitive
  has_many :terms
end
