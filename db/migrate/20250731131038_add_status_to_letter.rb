class AddStatusToLetter < ActiveRecord::Migration[8.0]
  def change
    add_column :letters, :status, :string
  end
end
