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

ActiveRecord::Schema.define(version: 2021_12_27_222517) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "items", force: :cascade do |t|
    t.string "directory"
    t.string "title"
    t.string "author"
    t.integer "copies"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "active", default: false, null: false
    t.string "publisher"
    t.string "physical_desc"
    t.boolean "complete", default: false, null: false
    t.index ["directory"], name: "index_items_on_directory", unique: true
  end

  create_table "items_terms", id: false, force: :cascade do |t|
    t.bigint "item_id", null: false
    t.bigint "term_id", null: false
    t.index ["item_id", "term_id"], name: "index_items_terms_on_item_id_and_term_id"
    t.index ["term_id", "item_id"], name: "index_items_terms_on_term_id_and_item_id"
  end

  create_table "loans", force: :cascade do |t|
    t.bigint "item_id", null: false
    t.string "patron_identifier"
    t.datetime "loan_date"
    t.datetime "due_date"
    t.datetime "return_date"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["item_id"], name: "index_loans_on_item_id"
    t.index ["patron_identifier"], name: "index_loans_on_patron_identifier"
  end

  create_table "session_counters", force: :cascade do |t|
    t.string "uid"
    t.boolean "student"
    t.boolean "staff"
    t.boolean "faculty"
    t.boolean "admin"
    t.integer "count"
  end

  create_table "settings", id: :integer, default: 1, force: :cascade do |t|
    t.bigint "default_term_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["default_term_id"], name: "index_settings_on_default_term_id"
    t.check_constraint "id = 1", name: "max_one_settings_row"
  end

  create_table "terms", force: :cascade do |t|
    t.string "name", null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["name"], name: "index_terms_on_name", unique: true
  end

  add_foreign_key "loans", "items"
  add_foreign_key "settings", "terms", column: "default_term_id"
end
