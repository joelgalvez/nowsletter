class AddBodyOriginalToLetters < ActiveRecord::Migration[8.0]
  def change
    add_column :letters, :body_original, :text
  end
end
