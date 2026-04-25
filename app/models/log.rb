class Log < ApplicationRecord
  belongs_to :venue, optional: true
  belongs_to :event, optional: true
  belongs_to :letter, optional: true
  belongs_to :user, optional: true

  validates :role, inclusion: { in: %w[admin editor], message: "%{value} is not a valid role" }
  validates :severity, inclusion: { in: %w[normal high critical], message: "%{value} is not a valid severity" }

  before_validation :set_defaults

  private

  def set_defaults
    self.role ||= "admin"
    self.severity ||= "normal"
    self.user ||= Current.user if defined?(Current) && Current.respond_to?(:user)
  end
end
