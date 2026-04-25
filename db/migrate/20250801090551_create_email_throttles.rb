class CreateEmailThrottles < ActiveRecord::Migration[8.0]
  def change
    create_table :email_throttles do |t|
      t.string :key
      t.datetime :last_sent_at

      t.timestamps
    end
    add_index :email_throttles, :key
  end
end
