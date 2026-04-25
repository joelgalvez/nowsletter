class CreateSubstitutes < ActiveRecord::Migration[8.1]
  def change
    create_table :substitutes do |t|
      t.string :long
      t.string :short
      t.references :llm_job, null: false, foreign_key: true

      t.timestamps
    end
  end
end
