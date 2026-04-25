class ChangeVenueInDefaultToFalse < ActiveRecord::Migration[8.0]
  def change
    change_column_default :venues, :in, false
  end
end
