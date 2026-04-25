class RenameInToOptInOnVenues < ActiveRecord::Migration[8.1]
  def change
    rename_column :venues, :in, :opt_in
  end
end
