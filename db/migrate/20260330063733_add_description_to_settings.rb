class AddDescriptionToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :description, :text
  end
end
