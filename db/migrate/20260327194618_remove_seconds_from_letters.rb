class RemoveSecondsFromLetters < ActiveRecord::Migration[8.1]
  def change
    remove_column :letters, :seconds, :integer
  end
end
