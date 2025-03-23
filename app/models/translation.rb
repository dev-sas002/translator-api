# == Schema Information
#
# Table name: translations
#
#  id                   :bigint           not null, primary key
#  source_language_code :string           not null
#  target_language_code :string           not null
#  source_text          :string(5000)     not null
#  glossary_id          :bigint
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
class Translation < ApplicationRecord
  belongs_to :glossary, optional: true
  validates :source_language_code, presence: true, inclusion: {in: Glossary::ISO_639_1_CODES}
  validates :target_language_code, presence: true, inclusion: {in: Glossary::ISO_639_1_CODES}
  validates :source_text, presence: true, length: {maximum: 5000}
  validate :glossary_match_languages

  def glossary_match_languages
    if glossary.present? && (source_language_code != glossary.source_language_code || target_language_code != glossary.target_language_code)
      errors.add(:glossary, "language codes do not match with the source and target language codes")
    end
  end
end
