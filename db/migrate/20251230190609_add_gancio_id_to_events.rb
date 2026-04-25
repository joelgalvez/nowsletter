class AddGancioIdToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :gancio_id, :integer
  end
end
