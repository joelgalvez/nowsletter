class AddAllTheThings < ActiveRecord::Migration[8.0]
  def change
    create_table "cities", force: :cascade do |t|
      t.string "name"
      t.integer "country_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index [ "country_id" ], name: "index_cities_on_country_id"
    end

    create_table "countries", force: :cascade do |t|
      t.string "country_code"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    create_table "events", force: :cascade do |t|
      t.datetime "start_date"
      t.datetime "end_date"
      t.string "title"
      t.text "description"
      t.string "lead_image"
      t.integer "letter_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "location"
      t.integer "position"
      t.integer "city_id"
      t.integer "venue_id", null: false
      t.string "uid"
      t.string "url"
      t.index [ "city_id" ], name: "index_events_on_city_id"
      t.index [ "letter_id" ], name: "index_events_on_letter_id"
      t.index [ "venue_id" ], name: "index_events_on_venue_id"
    end

    create_table "events_tags", id: false, force: :cascade do |t|
      t.integer "tag_id", null: false
      t.integer "event_id", null: false
    end

    create_table "letters", force: :cascade do |t|
      t.text "body"
      t.string "uid"
      t.string "subject"
      t.text "json"
      t.datetime "sent_date"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.text "text_version"
      t.integer "venue_id", null: false
      t.index [ "venue_id" ], name: "index_letters_on_venue_id"

      t.string "from"
      t.text "prompt"
      t.integer "seconds"
    end

    create_table "lists", force: :cascade do |t|
      t.string "title"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    create_table "lists_venues", id: false, force: :cascade do |t|
      t.integer "venue_id", null: false
      t.integer "list_id", null: false
    end


    create_table "senders", force: :cascade do |t|
      t.string "email"
      t.integer "venue_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.boolean "recipient", default: false
      t.index [ "email" ], name: "index_senders_on_email"
      t.index [ "venue_id" ], name: "index_senders_on_venue_id"
    end

    create_table "tags", force: :cascade do |t|
      t.string "title"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "count_cache"
      t.index [ "title" ], name: "index_tags_on_title", unique: true
    end

    create_table "tags_venues", id: false, force: :cascade do |t|
      t.integer "tag_id", null: false
      t.integer "venue_id", null: false
    end

    create_table "venues", force: :cascade do |t|
      t.string "title"
      t.string "website"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "visible"
      t.string "preview_key"
      t.string "code"
      t.integer "city_id"
      t.string "ics"
      t.index [ "city_id" ], name: "index_venues_on_city_id"
    end

    add_foreign_key "cities", "countries"
    add_foreign_key "events", "cities"
    add_foreign_key "events", "letters"
    add_foreign_key "events", "venues"
    add_foreign_key "letters", "venues"
    add_foreign_key "senders", "venues"
    add_foreign_key "venues", "cities"
  end
end
