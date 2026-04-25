class RemoveRecipientFromSenders < ActiveRecord::Migration[8.1]
  def change
    remove_column :senders, :recipient, :boolean
  end
end
