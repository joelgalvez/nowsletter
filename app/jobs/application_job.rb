class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  # Skip recurring jobs in non-production deployments (e.g., test)
  before_perform do |job|
    if job.class.recurring_job? && !Rails.env.production?
      Rails.logger.info "Skipping #{job.class.name} - not production (#{Rails.env})"
      throw :abort
    end
  end

  def self.recurring_job?
    # Check if this job is defined in config/recurring.yml
    false # Override in subclasses that are recurring jobs
  end
end
