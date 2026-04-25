class AddConfirmationTokenToSubscribers < ActiveRecord::Migration[8.0]
  def change
    add_column :subscribers, :confirmation_token, :string
    add_index :subscribers, :confirmation_token, unique: true
  end
end
