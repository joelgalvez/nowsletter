class AddVenueToUser < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :venue, null: true, foreign_key: true
  end
end
