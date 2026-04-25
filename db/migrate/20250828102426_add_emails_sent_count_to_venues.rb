class AddEmailsSentCountToVenues < ActiveRecord::Migration[8.0]
  def change
    add_column :venues, :emails_sent_count, :integer, default: 0, null: false
  end
end
