class DigestMailer < ApplicationMailer
  helper DateHelper

  def weekly
    @ongoing_events = OngoingEventsQuery.new(city: "Amsterdam").call

    @days = EventsByDayQuery.new(days: 14, city: "Amsterdam").call

    mail(
      to: User.admin_emails,
      subject: "#{ENV["APP_NAME"]} #{Date.today.strftime('%A, %B %d')}"
    )
  end
end
