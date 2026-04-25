class AddStatusToLlmJobs < ActiveRecord::Migration[8.1]
  def change
    add_column :llm_jobs, :status, :string, null: false, default: "new"
  end
end
