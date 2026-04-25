class SubscriberMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.subscriber_mailer.confirmation.subject
  #
  def confirmation(subscriber)
    @subscriber = subscriber
    @confirmation_url = confirm_subscriber_url(@subscriber.confirmation_token)

    mail(
      to: @subscriber.email,
      subject: "Confirm your subscription to weekly updates"
    )
  end
end
