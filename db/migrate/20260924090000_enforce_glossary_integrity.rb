# The model layer already rejected duplicate language pairs and dangling
# glossary references, but nothing stopped a second process, a console session
# or a bulk import from writing them. These constraints make the database the
# authority.
class EnforceGlossaryIntegrity < ActiveRecord::Migration[7.0]
  def up
    # A dangling reference cannot be turned into a valid one, so detach it
    # rather than fail the migration. `glossary_id` is nullable by design.
    execute(<<~SQL)
      UPDATE translations
         SET glossary_id = NULL
       WHERE glossary_id IS NOT NULL
         AND glossary_id NOT IN (SELECT id FROM glossaries)
    SQL

    add_index :glossaries, %i[source_language_code target_language_code],
      unique: true, name: "index_glossaries_on_language_pair"

    # Terms are always looked up by glossary, and the highlighter only ever
    # reads `source_term`, so this index answers that query from the index
    # alone.
    add_index :terms, %i[glossary_id source_term], name: "index_terms_on_glossary_id_and_source_term"

    # The single-column index is now a prefix of the composite one, so it can
    # only cost write throughput and disk.
    remove_index :terms, column: :glossary_id, name: "index_terms_on_glossary_id"

    add_foreign_key :translations, :glossaries, on_delete: :nullify
  end

  def down
    remove_foreign_key :translations, :glossaries
    add_index :terms, :glossary_id, name: "index_terms_on_glossary_id"
    remove_index :terms, name: "index_terms_on_glossary_id_and_source_term"
    remove_index :glossaries, name: "index_glossaries_on_language_pair"
  end
end
