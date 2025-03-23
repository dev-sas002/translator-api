# == Schema Information
#
# Table name: terms
#
#  id          :bigint           not null, primary key
#  source_term :string           not null
#  target_term :string           not null
#  glossary_id :bigint           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Term < ApplicationRecord
  # `touch: true` bumps the glossary's `updated_at` whenever a term is created,
  # updated or destroyed. Highlighting::MatcherCache keys on the glossary's
  # cache version, so this is what invalidates a compiled matcher.
  belongs_to :glossary, touch: true

  validates :source_term, presence: true
  validates :target_term, presence: true
end
