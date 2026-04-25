class AddLetterToLlmJobs < ActiveRecord::Migration[8.1]
  def change
    add_reference :llm_jobs, :letter, null: true, foreign_key: true
  end
end
