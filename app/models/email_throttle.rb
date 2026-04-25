class EmailThrottle < ApplicationRecord
  def self.can_send?(key, throttle_period = 24.hours)
    throttle = find_or_initialize_by(key: key)

    if throttle.last_sent_at.nil? || throttle.last_sent_at < throttle_period.ago
      throttle.update(last_sent_at: Time.current)
      true
    else
      false
    end
  end
end
