class LlmJob < ApplicationRecord
  belongs_to :letter
  has_many :substitutes, dependent: :destroy

  STATUSES = %w[new pending parsed processed error].freeze

  after_create_commit :notify_new_job, if: -> { status == "new" }

  validates :status, presence: true, inclusion: { in: STATUSES }
  validate :result_must_be_valid_json, if: -> { result.present? }

  before_save :sanitize_result, if: -> { result.present? && valid_json? }

  def process
    cleaned_text = result.gsub(/\[end of text\]\s*$/, "")
    substitutes.each do |sub|
      cleaned_text = cleaned_text.gsub(sub.short, sub.long)
    end

    events = JSON.parse(cleaned_text)

    ActiveRecord::Base.transaction do
      from = letter.from
      Sender.find_by(email: from.downcase) || Sender.create!(email: from.downcase, venue: letter.venue)
      venue = letter.venue

      events["events"].each do |event|
        start_date = parse_date(event["start_date_time"])
        end_date = parse_date(event["end_date_time"]) || start_date

        event_obj = Event.create(
          position: event["position"],
          start_date: start_date,
          end_date: end_date,
          lead_image: event["img"],
          title: event["title"]&.sub("&amp;", "&"),
          description: event["description"],
          letter: letter,
          venue: venue
        )

        unless event["country_code"].nil?
          country = Country.find_or_create_by(country_code: event["country_code"])
          city = City.find_or_create_by(name: event["city"], country: country) unless event["city"].nil?
        end

        unless event["tags"].nil?
          event["tags"].split(",").each do |tag|
            event_obj.tags << Tag.find_or_create_by!(title: tag.strip.downcase)
          end
        end

        event_obj.city = city
        event_obj.save
      end

      letter.update!(status: "processed")
      update!(status: "processed")
    end

    CacheLetterImagesJob.perform_later(letter.id)

    Log.create!(title: "Parsed Letter json", letter_id: letter.id, severity: "normal", role: "admin")
    Turbo::StreamsChannel.broadcast_refresh_to(letter)
  rescue JSON::ParserError
    update(status: "error")
    letter.update(status: "error")
    Log.create!(title: "JSON Parsing Error", letter_id: letter.id, severity: "high", role: "admin")
    Turbo::StreamsChannel.broadcast_refresh_to(letter)
  rescue => e
    update(status: "error")
    letter.update(status: "error")
    Log.create!(title: "Processing Error", text: e.message.to_s[0..200], letter_id: letter.id, severity: "high", role: "admin")
    Turbo::StreamsChannel.broadcast_refresh_to(letter)
  end

  private

  def notify_new_job
    ActionCable.server.broadcast("llm_jobs", { new_jobs: true })
    Turbo::StreamsChannel.broadcast_refresh_to(letter)
  end

  def parse_date(value)
    return nil if value.nil?
    parsed = ::Chronic.parse(value)
    Time.zone.parse(parsed.strftime("%Y-%m-%d %H:%M:%S")) if parsed
  end

  def valid_json?
    JSON.parse(result) && true
  rescue JSON::ParserError
    false
  end

  def result_must_be_valid_json
    errors.add(:result, "must be valid JSON") unless valid_json?
  end

  def sanitize_result
    helper = ActionController::Base.helpers
    self.result = JSON.generate(deep_sanitize(JSON.parse(result), helper))
  end

  def deep_sanitize(obj, helper)
    case obj
    when Hash
      obj.transform_values { |v| deep_sanitize(v, helper) }
    when Array
      obj.map { |v| deep_sanitize(v, helper) }
    when String
      clean = helper.strip_tags(obj)
      # Nullify dangerous URL schemes (javascript:, data:, vbscript:, etc.) but allow http(s) and plain text.
      # Real URL schemes never have whitespace right after the colon — "Opening: foo" is a title.
      clean.match?(/\A[a-z][a-z0-9+.\-]*:\S/i) && !clean.match?(/\Ahttps?:\/\//i) ? nil : clean
    else
      obj
    end
  end
end
