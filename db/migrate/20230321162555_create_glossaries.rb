class CreateGlossaries < ActiveRecord::Migration[7.0]
  def change
    create_table :glossaries do |t|
      t.string :source_language_code, null: false
      t.string :target_language_code, null: false
      t.timestamps
    end
  end
end
