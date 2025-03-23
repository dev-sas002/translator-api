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
  belongs_to :glossary

  validates :source_term, presence: true
  validates :target_term, presence: true
end
