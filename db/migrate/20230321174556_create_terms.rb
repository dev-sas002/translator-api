class CreateTerms < ActiveRecord::Migration[7.0]
  def change
    create_table :terms do |t|
      t.string :source_term, null: false
      t.string :target_term, null: false
      t.belongs_to :glossary, null: false, foreign_key: true
      t.timestamps
    end
  end
end
