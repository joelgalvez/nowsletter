# Preview all emails at http://localhost:3000/rails/mailers/subscriber_mailer
class SubscriberMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/subscriber_mailer/confirmation
  def confirmation
    SubscriberMailer.confirmation
  end
end
