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

ActiveRecord::Schema[8.1].define(version: 2026_04_19_201315) do
  create_table "action_mailbox_inbound_emails", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "message_checksum", null: false
    t.string "message_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "message_checksum"], name: "index_action_mailbox_inbound_emails_uniqueness", unique: true
  end

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "available_models", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_available_models_on_name", unique: true
  end

  create_table "blacklists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "url"
  end

  create_table "cities", force: :cascade do |t|
    t.integer "country_id", null: false
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["country_id"], name: "index_cities_on_country_id"
  end

  create_table "countries", force: :cascade do |t|
    t.string "country_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "email_templates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key"
    t.text "text"
    t.datetime "updated_at", null: false
  end

  create_table "email_throttles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key"
    t.datetime "last_sent_at"
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_email_throttles_on_key"
  end

  create_table "events", force: :cascade do |t|
    t.integer "city_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "end_date"
    t.string "lead_image"
    t.string "lead_image_cached"
    t.integer "letter_id"
    t.string "location"
    t.integer "position"
    t.datetime "start_date"
    t.string "status"
    t.string "title"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.string "url"
    t.integer "venue_id", null: false
    t.index ["city_id"], name: "index_events_on_city_id"
    t.index ["letter_id"], name: "index_events_on_letter_id"
    t.index ["venue_id"], name: "index_events_on_venue_id"
  end

  create_table "events_tags", id: false, force: :cascade do |t|
    t.integer "event_id", null: false
    t.integer "tag_id", null: false
  end

  create_table "global_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key"
    t.datetime "updated_at", null: false
    t.string "value"
  end

  create_table "letters", force: :cascade do |t|
    t.text "body"
    t.text "body_cached"
    t.datetime "created_at", null: false
    t.string "from"
    t.text "json"
    t.datetime "pending_at"
    t.text "prompt"
    t.datetime "sent_date"
    t.string "status"
    t.string "subject"
    t.text "text_version"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.integer "venue_id", null: false
    t.index ["venue_id"], name: "index_letters_on_venue_id"
  end

  create_table "lists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "lists_venues", id: false, force: :cascade do |t|
    t.integer "list_id", null: false
    t.integer "venue_id", null: false
  end

  create_table "llm_jobs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "letter_id", null: false
    t.string "model"
    t.text "prompt"
    t.text "result"
    t.integer "seconds"
    t.string "status", default: "new", null: false
    t.datetime "updated_at", null: false
    t.index ["letter_id"], name: "index_llm_jobs_on_letter_id"
  end

  create_table "logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "event_id"
    t.integer "letter_id"
    t.string "role"
    t.string "severity"
    t.text "text"
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "venue_id"
    t.index ["event_id"], name: "index_logs_on_event_id"
    t.index ["letter_id"], name: "index_logs_on_letter_id"
    t.index ["user_id"], name: "index_logs_on_user_id"
    t.index ["venue_id"], name: "index_logs_on_venue_id"
  end

  create_table "messages", force: :cascade do |t|
    t.integer "big"
    t.integer "can_close"
    t.string "close_text"
    t.string "color"
    t.datetime "created_at", null: false
    t.integer "list_id", null: false
    t.integer "order"
    t.string "text"
    t.datetime "updated_at", null: false
    t.index ["list_id"], name: "index_messages_on_list_id"
  end

  create_table "pages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "slug"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "posts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "text"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "prompts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "text"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "senders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.datetime "updated_at", null: false
    t.integer "venue_id", null: false
    t.index ["email"], name: "index_senders_on_email"
    t.index ["venue_id"], name: "index_senders_on_venue_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.datetime "updated_at", null: false
    t.string "value"
  end

  create_table "subscribers", force: :cascade do |t|
    t.text "comment"
    t.string "confirmation_token"
    t.boolean "confirmed", default: false, null: false
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "email"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["confirmation_token"], name: "index_subscribers_on_confirmation_token", unique: true
    t.index ["user_id"], name: "index_subscribers_on_user_id", unique: true
  end

  create_table "substitutes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "llm_job_id", null: false
    t.string "long"
    t.string "short"
    t.datetime "updated_at", null: false
    t.index ["llm_job_id"], name: "index_substitutes_on_llm_job_id"
  end

  create_table "tags", force: :cascade do |t|
    t.integer "count_cache"
    t.datetime "created_at", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["title"], name: "index_tags_on_title", unique: true
  end

  create_table "tags_venues", id: false, force: :cascade do |t|
    t.integer "tag_id", null: false
    t.integer "venue_id", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "api_token"
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.datetime "last_dashboard_visit"
    t.string "login_token"
    t.datetime "login_token_expires_at"
    t.string "password_digest", null: false
    t.string "role"
    t.datetime "updated_at", null: false
    t.integer "venue_id"
    t.index ["api_token"], name: "index_users_on_api_token", unique: true
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["login_token"], name: "index_users_on_login_token", unique: true
    t.index ["venue_id"], name: "index_users_on_venue_id"
  end

  create_table "venues", force: :cascade do |t|
    t.boolean "accept_help"
    t.boolean "checked", default: false
    t.integer "city_id"
    t.string "code"
    t.datetime "created_at", null: false
    t.integer "emails_sent_count", default: 0, null: false
    t.boolean "opt_in", default: false
    t.boolean "opt_out", default: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "visible"
    t.string "website"
    t.index ["city_id"], name: "index_venues_on_city_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "cities", "countries"
  add_foreign_key "events", "cities"
  add_foreign_key "events", "letters"
  add_foreign_key "events", "venues"
  add_foreign_key "letters", "venues"
  add_foreign_key "llm_jobs", "letters"
  add_foreign_key "logs", "events"
  add_foreign_key "logs", "letters"
  add_foreign_key "logs", "users"
  add_foreign_key "logs", "venues"
  add_foreign_key "senders", "venues"
  add_foreign_key "sessions", "users"
  add_foreign_key "subscribers", "users"
  add_foreign_key "substitutes", "llm_jobs"
  add_foreign_key "users", "venues"
  add_foreign_key "venues", "cities"
end
