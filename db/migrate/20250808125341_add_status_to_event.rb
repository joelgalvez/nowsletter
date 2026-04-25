class AddStatusToEvent < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :status, :string
  end
end
