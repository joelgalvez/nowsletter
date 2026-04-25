class CreateActivitypubTables < ActiveRecord::Migration[8.1]
  def change
    create_table :activitypub_followers do |t|
      t.string :actor_uri, null: false
      t.string :inbox_url, null: false
      t.string :shared_inbox_url
      t.timestamps
    end
    add_index :activitypub_followers, :actor_uri, unique: true

    create_table :activitypub_deliveries do |t|
      t.references :event, null: false, foreign_key: true
      t.string :inbox_url, null: false
      t.string :activity_type, null: false
      t.string :status, null: false, default: "pending"
      t.integer :attempts, null: false, default: 0
      t.datetime :last_attempted_at
      t.text :last_error
      t.timestamps
    end
    add_index :activitypub_deliveries, [ :event_id, :inbox_url, :activity_type ],
              name: "idx_ap_deliveries_unique", unique: true

    add_column :events, :activitypub_published_at, :datetime
  end
end
