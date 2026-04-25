class RemovePreviewKeyFromVenues < ActiveRecord::Migration[8.1]
  def change
    remove_column :venues, :preview_key, :string
  end
end
