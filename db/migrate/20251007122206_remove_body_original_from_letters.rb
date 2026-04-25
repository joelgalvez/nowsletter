class RemoveBodyOriginalFromLetters < ActiveRecord::Migration[8.0]
  def change
    remove_column :letters, :body_original, :text
  end
end
