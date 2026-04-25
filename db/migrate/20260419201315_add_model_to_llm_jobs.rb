class AddModelToLlmJobs < ActiveRecord::Migration[8.1]
  def change
    add_column :llm_jobs, :model, :string
  end
end
