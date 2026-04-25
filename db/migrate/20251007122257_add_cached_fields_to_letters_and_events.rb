class AddCachedFieldsToLettersAndEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :letters, :body_cached, :text
    add_column :events, :lead_image_cached, :string
  end
end
