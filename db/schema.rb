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

ActiveRecord::Schema.define(version: 2021_05_24_191719) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "assignments", force: :cascade do |t|
    t.bigint "framework_users_id", null: false
    t.bigint "role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["framework_users_id"], name: "index_assignments_on_framework_users_id"
    t.index ["role_id"], name: "index_assignments_on_role_id"
  end

  create_table "framework_users", force: :cascade do |t|
    t.integer "lcasid", null: false
    t.string "name", null: false
    t.string "role", null: false
    t.string "email"
  end

  create_table "lending_items", force: :cascade do |t|
    t.string "barcode"
    t.string "filename"
    t.string "title"
    t.string "author"
    t.string "millennium_record"
    t.string "alma_record"
    t.integer "copies"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "proxy_borrower_requests", force: :cascade do |t|
    t.string "faculty_name"
    t.string "department"
    t.string "faculty_id"
    t.string "student_name"
    t.string "student_dsp"
    t.string "dsp_rep"
    t.string "research_last", null: false
    t.string "research_first", null: false
    t.string "research_middle"
    t.date "date_term"
    t.integer "renewal", default: 0
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "user_email"
  end

  create_table "roles", force: :cascade do |t|
    t.string "role", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "stack_requests", force: :cascade do |t|
    t.string "email"
    t.string "name"
    t.string "phone"
    t.date "pass_date"
    t.boolean "main_stack"
    t.string "local_id"
    t.boolean "approvedeny"
    t.string "processed_by"
    t.string "denial_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type"
    t.string "affiliation"
    t.text "research_desc"
    t.date "pass_date_end"
  end

  add_foreign_key "assignments", "framework_users", column: "framework_users_id"
end
