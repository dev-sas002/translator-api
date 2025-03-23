# Whether a glossary's terms are matched case-sensitively. Defaults to true so
# existing glossaries keep the behaviour they had before the column existed.
class AddCaseSensitiveToGlossaries < ActiveRecord::Migration[7.0]
  def change
    add_column :glossaries, :case_sensitive, :boolean, null: false, default: true
  end
end
