class AddApprovalToActivitypubFollowers < ActiveRecord::Migration[8.1]
  def change
    add_column :activitypub_followers, :status, :string, null: false, default: "pending"
    add_column :activitypub_followers, :display_name, :string
    add_column :activitypub_followers, :profile_url, :string
    add_column :activitypub_followers, :requested_at, :datetime
    add_column :activitypub_followers, :responded_at, :datetime
    add_column :activitypub_followers, :follow_activity, :text

    add_index :activitypub_followers, :status
  end
end
