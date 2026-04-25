class AddEmailAndCommentToSubscribers < ActiveRecord::Migration[8.0]
  def change
    add_column :subscribers, :email, :string
    add_column :subscribers, :comment, :text
  end
end
