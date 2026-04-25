class Subscriber < ApplicationRecord
  belongs_to :user

  validates :user_id, presence: true, uniqueness: true

  before_create :generate_confirmation_token

  private

  def generate_confirmation_token
    self.confirmation_token = SecureRandom.urlsafe_base64(32)
  end
end
