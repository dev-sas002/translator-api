class CreateTranslations < ActiveRecord::Migration[7.0]
  def change
    create_table :translations do |t|
      t.string :source_language_code, null: false
      t.string :target_language_code, null: false
      t.string :source_text, limit: 5000, null: false
      t.belongs_to :glossary, optional: true
      t.timestamps
    end
  end
end
