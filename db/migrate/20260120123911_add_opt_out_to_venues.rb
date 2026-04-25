class AddOptOutToVenues < ActiveRecord::Migration[8.1]
  def change
    add_column :venues, :opt_out, :boolean, default: false
  end
end
