require "test_helper"

class SubscriberMailerTest < ActionMailer::TestCase
  test "confirmation" do
    subscriber = Subscriber.new(email: "to@example.org", confirmation_token: "token123")
    mail = SubscriberMailer.confirmation(subscriber)
    assert_equal "Confirm your subscription to weekly updates", mail.subject
    assert_equal [ "to@example.org" ], mail.to
    assert_match "Thanks for subscribing", mail.body.encoded
  end
end
