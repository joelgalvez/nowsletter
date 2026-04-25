class AddSecondsToLlmJobs < ActiveRecord::Migration[8.1]
  def change
    add_column :llm_jobs, :seconds, :integer
  end
end
