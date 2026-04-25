class SetDefaultForVenueIn < ActiveRecord::Migration[8.0]
  def change
    change_column_default :venues, :in, true

    # Update all existing venues to have in = true
    reversible do |dir|
      dir.up do
        Venue.update_all(in: true)
      end
    end
  end
end
