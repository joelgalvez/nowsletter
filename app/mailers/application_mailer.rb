class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV["DEFAULT_FROM_EMAIL"].presence || "noreply@example.com" }
  layout "mailer"
end
