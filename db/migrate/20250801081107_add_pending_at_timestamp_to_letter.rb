class AddPendingAtTimestampToLetter < ActiveRecord::Migration[8.0]
  def change
    add_column :letters, :pending_at, :timestamp
  end
end
