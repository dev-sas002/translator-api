# == Schema Information
#
# Table name: glossaries
#
#  id                   :bigint           not null, primary key
#  source_language_code :string           not null
#  target_language_code :string           not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
class Glossary < ApplicationRecord
  ISO_639_1_CODES = ["aa", "ab", "ae", "af", "ak", "am", "an", "ar", "as", "av", "ay", "az", "ba", "be", "bg", "bi", "bm", "bn", "bo", "br", "bs", "ca", "ce", "ch", "co", "cr", "cs", "cv", "cy", "da", "de", "dv", "dz", "ee", "en", "eo", "es", "et", "eu", "fa", "ff", "fi", "fj", "fo", "fr", "fy", "ga", "gl", "gn", "gu", "gv", "ha", "he", "hi", "ho", "hr", "hu", "hy", "hz", "ia", "id", "ie", "ig", "ik", "io", "is", "it", "iu", "ja", "jv", "ka", "kg", "kj", "kk", "kl", "km", "kn", "ko", "kr", "ks", "ku", "kv", "kw", "la", "lb", "lg", "ln", "lo", "lt", "lu", "lv", "mg", "mh", "mi", "mk", "ml", "mn", "mr", "ms", "mt", "my", "na", "ne", "ng", "nl", "no", "oj", "om", "or", "os", "pa", "pi", "pl", "ps", "pt", "qu", "rm", "rn", "ro", "ru", "rw", "sa", "sc", "sd", "se", "sg", "sk", "sl", "sm", "sn", "so", "sq", "sr", "ss", "su", "sv", "sw", "ta", "te", "tg", "th", "ti", "tk", "tl", "tn", "to", "tr", "ts", "tt", "tw", "ty", "ug", "uk", "ur", "uz", "ve", "vi", "wa", "wo", "xh", "yi", "yo", "za", "zh", "zu"]
  has_many :terms, dependent: :destroy

  validates :source_language_code, presence: true, inclusion: {in: ISO_639_1_CODES}
  validates :target_language_code, presence: true, inclusion: {in: ISO_639_1_CODES}
  validates :source_language_code, uniqueness: {scope: :target_language_code}
end
