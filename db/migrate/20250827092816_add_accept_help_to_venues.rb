class AddAcceptHelpToVenues < ActiveRecord::Migration[8.0]
  def change
    add_column :venues, :accept_help, :boolean
  end
end
