class RemoveIcsFromVenues < ActiveRecord::Migration[8.1]
  def change
    remove_column :venues, :ics, :string
  end
end
