class ChangeLetterIdNullOnLlmJobs < ActiveRecord::Migration[8.1]
  def change
    change_column_null :llm_jobs, :letter_id, false
  end
end
