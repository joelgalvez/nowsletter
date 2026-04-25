class LetterMailer < ApplicationMailer
  def pending_letters_warning(letter_ids)
    @letters = Letter.where(id: letter_ids)
    @count = @letters.count

    mail(
      to: User.admin_emails,
      subject: "Warning: #{@count} letters have been pending for over 2 hours"
    )
  end

  # Class method to send emails to all users - works for both test and production
  def self.send_to_all_users(letter, template:, subject:)
    # Check global test mode setting
    test_mode = GlobalSetting.test_mode?

    # Determine recipients based on test mode
    if test_mode
      users = [ User.find_by(role: "admin") || User.first ]
    else
      # Get all users associated with the venue
      users = letter.venue.users.where.not(email_address: nil)
      return if users.empty?
    end

    # Send individual emails to each user with their own login token
    users.each do |user|
      send_to_user(letter, user, template: template, subject: subject).deliver_later
    end
  end

  # Instance method to send email to a single user
  def send_to_user(letter, user, template:, subject:)
    @letter = letter
    @venue = letter.venue
    @events = @letter.events
    @count = @events.count
    @user = user
    # Generate a unique login token for this user valid for 1 week
    @login_token = @user.generate_login_token!(expires_in: 4.week)

    mail(
      to: @user.email_address,
      bcc: User.admin_emails,
      subject: subject,
      template_name: template
    )
  end

  # Send a custom-body email to a single editor of the venue.
  # `to:` may be overridden (e.g. in test mode) so the message is delivered
  # to a different address while still containing the editor's own login token.
  def custom_template(letter, user, body:, subject:, to: nil)
    @letter = letter
    @venue = letter.venue
    @events = @letter.events
    @count = @events.count
    @user = user
    @body = body
    @login_token = @user.generate_login_token!(expires_in: 4.week)

    mail(
      to: to || @user.email_address,
      bcc: User.admin_emails,
      subject: subject
    )
  end

  def venue_opted_out(venue)
    @venue = venue

    mail(
      to: User.admin_emails,
      subject: "Venue opted out: #{@venue.title}"
    )
  end

  def test_system_notification
    mail(
      to: User.admin_emails,
      subject: "Test system notification email"
    )
  end

  def new_email_received(letter, user)
    @letter = letter
    @venue = letter.venue
    @from = letter.from
    @subject = letter.subject
    @sent_date = letter.sent_date
    @user = user
    @login_token = user.generate_login_token!(expires_in: 4.weeks)

    mail(
      to: user.email_address,
      subject: "New email received from #{@from}"
    )
  end
end
