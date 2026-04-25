namespace :llm_jobs do
  desc "Reset LlmJobs stuck in 'pending' older than AGE seconds (default 3600) back to 'new'"
  task :reset_stuck_pending, [ :age_seconds ] => :environment do |_, args|
    age = (args[:age_seconds] || 3600).to_i
    cutoff = age.seconds.ago

    scope = LlmJob.where(status: "pending").where("updated_at < ?", cutoff)
    stuck_ids = scope.pluck(:id)

    if stuck_ids.empty?
      puts "No pending LlmJobs older than #{age}s found."
      next
    end

    puts "Resetting #{stuck_ids.size} stuck pending LlmJob(s) to 'new': #{stuck_ids.inspect}"
    scope.update_all(status: "new", updated_at: Time.current)
    puts "Done."
  end
end
