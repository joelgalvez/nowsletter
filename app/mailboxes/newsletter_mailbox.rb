class NewsletterMailbox < ApplicationMailbox
  before_processing :find_venue

  def process
    return bounce unless @venue
    return if Letter.exists?(uid: mail.message_id)

    newsletter = extract_html_body
    return unless newsletter.present?

    letter = Letter.create!(
      body: newsletter.force_encoding("UTF-8"),
      uid: mail.message_id,
      from: mail.from&.first,
      subject: mail.subject,
      sent_date: mail.date,
      venue: @venue,
      status: "precheck"
    )

    if @venue.checked?
      letter.create_llm_job
    end

    User.admins.each do |admin|
      begin
        LetterMailer.new_email_received(letter, admin).deliver_later
      rescue => e
        Rails.logger.error "ERROR sending notification for letter #{letter.id} to #{admin.email_address}: #{e.class.name} - #{e.message}"
      end
    end
  end

  private

  def find_venue
    prefix = ENV["EMAIL_PREFIX_PATTERN"]
    recipient = mail.to&.find { |addr| addr.include?(prefix) }
    return unless recipient

    code = recipient.split("@").first.split(prefix).last
    @venue = Venue.find_by(code: code)
  end

  def extract_html_body
    if mail.html_part
      mail.html_part.body.decoded
    elsif mail.multipart? && mail.text_part
      mail.text_part.body.decoded.gsub("\r\n", "<br>")
    else
      mail.body.decoded
    end
  end
end
