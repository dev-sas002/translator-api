# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_03_21_183248) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "glossaries", force: :cascade do |t|
    t.string "source_language_code", null: false
    t.string "target_language_code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "terms", force: :cascade do |t|
    t.string "source_term", null: false
    t.string "target_term", null: false
    t.bigint "glossary_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["glossary_id"], name: "index_terms_on_glossary_id"
  end

  create_table "translations", force: :cascade do |t|
    t.string "source_language_code", null: false
    t.string "target_language_code", null: false
    t.string "source_text", limit: 5000, null: false
    t.bigint "glossary_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["glossary_id"], name: "index_translations_on_glossary_id"
  end

  add_foreign_key "terms", "glossaries"
end
