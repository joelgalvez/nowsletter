class AddCheckedToVenues < ActiveRecord::Migration[8.1]
  def change
    add_column :venues, :checked, :boolean, default: false
  end
end
