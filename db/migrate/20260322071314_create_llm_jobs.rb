class CreateLlmJobs < ActiveRecord::Migration[8.1]
  def change
    create_table :llm_jobs do |t|
      t.text :prompt
      t.text :result

      t.timestamps
    end
  end
end
