class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_one :subscriber, dependent: :destroy
  belongs_to :venue, optional: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  ROLES = %w[admin editor parser subscriber].freeze

  scope :admins, -> { where(role: "admin") }

  def self.admin_emails
    admins.pluck(:email_address)
  end

  before_create :generate_api_token

  def admin?
    role == "admin"
  end

  def editor?
    role == "editor"
  end

  def parser?
    role == "parser"
  end

  def subscriber?
    role == "subscriber"
  end

  attr_reader :raw_api_token

  def regenerate_api_token!
    generate_api_token
    save!
  end

  def generate_login_token!(expires_in: 1.week)
    self.login_token = SecureRandom.urlsafe_base64(32)
    self.login_token_expires_at = expires_in.from_now
    save!
    login_token
  end

  def valid_login_token?(token)
    return false if token.blank? || login_token.blank?
    return false if login_token_expires_at && login_token_expires_at < Time.current

    ActiveSupport::SecurityUtils.secure_compare(token, login_token)
  end

  def clear_login_token!
    update!(login_token: nil, login_token_expires_at: nil)
  end

  private

  def generate_api_token
    raw = SecureRandom.hex(32)
    self.api_token = Digest::SHA256.hexdigest(raw)
    @raw_api_token = raw
  end
end
