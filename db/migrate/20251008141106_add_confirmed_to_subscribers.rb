class AddConfirmedToSubscribers < ActiveRecord::Migration[8.0]
  def change
    add_column :subscribers, :confirmed, :boolean, default: false, null: false
    add_column :subscribers, :confirmed_at, :datetime
  end
end
