class CreateBlacklists < ActiveRecord::Migration[8.0]
  def change
    create_table :blacklists do |t|
      t.string :url

      t.timestamps
    end
  end
end
