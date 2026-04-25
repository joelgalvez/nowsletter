class CreateLetters < ActiveRecord::Migration[8.0]
  def change
    create_table "letters", force: :cascade do |t|
    t.string "from"
    t.string "code"
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uid"
    t.string "subject"
    t.text "json"
    t.datetime "sent_date"
    t.text "prompt"
    t.integer "seconds"
  end
  end
end
