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

ActiveRecord::Schema[7.0].define(version: 2023_04_18_203538) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "assignments", force: :cascade do |t|
    t.bigint "framework_users_id", null: false
    t.bigint "role_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["framework_users_id"], name: "index_assignments_on_framework_users_id"
    t.index ["role_id"], name: "index_assignments_on_role_id"
  end

  create_table "framework_users", force: :cascade do |t|
    t.integer "lcasid", null: false
    t.string "name", null: false
    t.string "role", null: false
    t.string "email"
  end

  create_table "good_job_batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.jsonb "serialized_properties"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_discard"
    t.text "callback_queue_name"
    t.integer "callback_priority"
    t.datetime "enqueued_at"
    t.datetime "discarded_at"
    t.datetime "finished_at"
  end

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "state"
  end

  create_table "good_job_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "key"
    t.jsonb "value"
    t.index ["key"], name: "index_good_job_settings_on_key", unique: true
  end

  create_table "good_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "queue_name"
    t.integer "priority"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "performed_at"
    t.datetime "finished_at"
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id"
    t.text "concurrency_key"
    t.text "cron_key"
    t.uuid "retried_good_job_id"
    t.datetime "cron_at"
    t.uuid "batch_id"
    t.uuid "batch_callback_id"
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["active_job_id"], name: "index_good_jobs_on_active_job_id"
    t.index ["batch_callback_id"], name: "index_good_jobs_on_batch_callback_id", where: "(batch_callback_id IS NOT NULL)"
    t.index ["batch_id"], name: "index_good_jobs_on_batch_id", where: "(batch_id IS NOT NULL)"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at", unique: true
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at", where: "((retried_good_job_id IS NULL) AND (finished_at IS NOT NULL))"
    t.index ["priority", "created_at"], name: "index_good_jobs_jobs_on_priority_created_at_when_unfinished", order: { priority: "DESC NULLS LAST" }, where: "(finished_at IS NULL)"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_and_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
  end

  create_table "holdings_records", force: :cascade do |t|
    t.bigint "holdings_request_id", null: false
    t.string "oclc_number", null: false
    t.string "ht_record_url"
    t.string "ht_error"
    t.boolean "ht_retrieved", default: false, null: false
    t.string "wc_symbols"
    t.string "wc_error"
    t.boolean "wc_retrieved", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["holdings_request_id", "oclc_number"], name: "index_holdings_records_on_holdings_request_id_and_oclc_number", unique: true
    t.index ["holdings_request_id"], name: "index_holdings_records_on_holdings_request_id"
  end

  create_table "holdings_requests", force: :cascade do |t|
    t.string "email", null: false
    t.string "filename", null: false
    t.boolean "rlf", default: false, null: false
    t.boolean "uc", default: false, null: false
    t.boolean "hathi", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "immediate", default: false, null: false
    t.datetime "scheduled_at"
  end

  create_table "host_bib_linked_bibs", force: :cascade do |t|
    t.bigint "host_bib_id", null: false
    t.bigint "linked_bib_id", null: false
    t.index ["host_bib_id"], name: "index_host_bib_linked_bibs_on_host_bib_id"
    t.index ["linked_bib_id"], name: "index_host_bib_linked_bibs_on_linked_bib_id"
  end

  create_table "host_bib_tasks", force: :cascade do |t|
    t.string "filename", null: false
    t.string "email"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "host_bibs", force: :cascade do |t|
    t.string "mms_id"
    t.integer "marc_status"
    t.bigint "host_bib_task_id", null: false
    t.datetime "updated_at"
    t.index ["host_bib_task_id"], name: "index_host_bibs_on_host_bib_task_id"
  end

  create_table "item_note_tasks", force: :cascade do |t|
    t.string "job_id", null: false
    t.boolean "completed", default: false
    t.boolean "started_email_sent", default: false
    t.boolean "completed_email_sent", default: false
    t.string "environment", null: false
    t.string "set_id", null: false
    t.string "note_text", null: false
    t.integer "note_num", null: false
    t.string "email", null: false
    t.integer "offset", default: 0
    t.integer "item_count"
    t.datetime "job_completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "set_name"
  end

  create_table "linked_bibs", force: :cascade do |t|
    t.string "mms_id"
    t.integer "marc_status"
    t.string "ldr_6"
    t.string "ldr_7"
    t.string "field_035"
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "user_email"
  end

  create_table "roles", force: :cascade do |t|
    t.string "role", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "type"
    t.string "affiliation"
    t.text "research_desc"
    t.date "pass_date_end"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "assignments", "framework_users", column: "framework_users_id"
  add_foreign_key "assignments", "roles"
  add_foreign_key "holdings_records", "holdings_requests"
  add_foreign_key "host_bib_linked_bibs", "host_bibs"
  add_foreign_key "host_bib_linked_bibs", "linked_bibs"
  add_foreign_key "host_bibs", "host_bib_tasks"
end
