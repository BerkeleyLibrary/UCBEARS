# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_09_07_193406) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "lending_item_loans", force: :cascade do |t|
    t.bigint "lending_item_id", null: false
    t.string "patron_identifier"
    t.datetime "loan_date"
    t.datetime "due_date"
    t.datetime "return_date"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["lending_item_id"], name: "index_lending_item_loans_on_lending_item_id"
    t.index ["patron_identifier"], name: "index_lending_item_loans_on_patron_identifier"
  end

  create_table "lending_items", force: :cascade do |t|
    t.string "directory"
    t.string "title"
    t.string "author"
    t.integer "copies"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "active", default: false, null: false
    t.string "publisher"
    t.string "physical_desc"
    t.index ["directory"], name: "index_lending_items_on_directory", unique: true
  end

  create_table "session_counters", force: :cascade do |t|
    t.string "uid"
    t.boolean "student"
    t.boolean "staff"
    t.boolean "faculty"
    t.boolean "admin"
    t.integer "count"
  end

  add_foreign_key "lending_item_loans", "lending_items"
end
