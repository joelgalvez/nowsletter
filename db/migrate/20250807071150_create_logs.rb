class CreateLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :logs do |t|
      t.string :title
      t.references :venue, null: true, foreign_key: true
      t.string :role
      t.string :severity

      t.timestamps
    end
  end
end
