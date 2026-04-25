class RemoveActivitypubAndGancio < ActiveRecord::Migration[8.1]
  def up
    remove_foreign_key :activitypub_deliveries, :events
    drop_table :activitypub_deliveries
    drop_table :activitypub_followers
    remove_column :events, :activitypub_published_at
    remove_column :events, :gancio_id
  end

  def down
    add_column :events, :gancio_id, :integer
    add_column :events, :activitypub_published_at, :datetime

    create_table :activitypub_followers do |t|
      t.string :actor_uri, null: false
      t.string :inbox_url, null: false
      t.string :status, default: "pending"
      t.boolean :approved, default: false
      t.timestamps
    end
    add_index :activitypub_followers, :actor_uri, unique: true
    add_index :activitypub_followers, :status

    create_table :activitypub_deliveries do |t|
      t.references :event, null: false, foreign_key: true
      t.string :inbox_url
      t.string :status
      t.text :payload
      t.timestamps
    end
    add_foreign_key :activitypub_deliveries, :events
  end
end
