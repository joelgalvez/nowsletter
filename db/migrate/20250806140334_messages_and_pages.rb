class MessagesAndPages < ActiveRecord::Migration[8.0]
  def change
    create_table "messages", force: :cascade do |t|
      t.string "text"
      t.integer "can_close"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "close_text"
      t.string "color"
      t.integer "order"
      t.integer "list_id", null: false
      t.integer "big"
      t.index [ "list_id" ], name: "index_messages_on_list_id"
    end

    create_table "pages", force: :cascade do |t|
      t.string "title"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "slug"
    end
  end
end
