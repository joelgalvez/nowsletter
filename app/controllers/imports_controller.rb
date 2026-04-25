class ImportsController < ApplicationController
  def index
    @venues = Venue.all.order(:title)
  end

  def preview
    @venues = Venue.all.order(:title)
    @text = params[:text]
    @venue_id = params[:venue_id]

    @error = validate_json(@text)

    if @error
      render :index, status: :unprocessable_entity
      return
    end

    json = JSON.parse(@text)
    @venue = Venue.find_by(id: @venue_id)

    # Check if any event is missing venue in JSON
    events_missing_venue = json["events"].any? { |e| e["venue"].blank? }

    if events_missing_venue && @venue.nil?
      @error = "Please select a venue (some events don't have venue in JSON)"
      render :index, status: :unprocessable_entity
      return
    end

    @tags = Tag.all.order(:title)
    @preview_events = json["events"].map do |event_data|
      matched_venue = if event_data["venue"].present?
        find_venue_by_title(event_data["venue"])
      end

      {
        title: event_data["title"],
        start_date: event_data["start-date-time"],
        end_date: event_data["end-date-time"],
        tags: event_data["tags"],
        venue_name: event_data["venue"],
        venue_id: matched_venue&.id || @venue&.id
      }
    end
  end

  def create
    city = City.joins(:country).find_by(name: "Amsterdam", country: { country_code: "NL" })
    created_count = 0

    params[:events].values.each do |event_params|
      venue = Venue.find_by(id: event_params[:venue_id])
      next unless venue

      tags = (event_params[:tag_ids] || []).map { |id| Tag.find_by(id: id) }.compact

      Event.create!(
        venue: venue,
        city: city,
        title: event_params[:title],
        start_date: Time.parse(event_params[:start_date]),
        end_date: Time.parse(event_params[:end_date]),
        tags: tags,
        status: "published"
      )
      created_count += 1
    end

    redirect_to import_path, notice: "Successfully imported #{created_count} event(s)"
  end

  private

  def validate_json(text)
    return "JSON is required" if text.blank?

    begin
      json = JSON.parse(text)
    rescue JSON::ParserError => e
      return "Invalid JSON: #{e.message}"
    end

    return "Missing 'events' array" unless json["events"]
    return "'events' must be an array" unless json["events"].is_a?(Array)

    json["events"].each_with_index do |event, i|
      return "Event #{i + 1}: missing or invalid 'title'" unless event["title"].is_a?(String)
      return "Event #{i + 1}: missing or invalid 'start-date-time'" unless event["start-date-time"].is_a?(String)
      return "Event #{i + 1}: 'start-date-time' must be in format 'YYYY-MM-DD HH:MM'" unless valid_datetime?(event["start-date-time"])
      return "Event #{i + 1}: missing or invalid 'end-date-time'" unless event["end-date-time"].is_a?(String)
      return "Event #{i + 1}: 'end-date-time' must be in format 'YYYY-MM-DD HH:MM'" unless valid_datetime?(event["end-date-time"])
      return "Event #{i + 1}: missing or invalid 'tags' array" unless event["tags"].is_a?(Array)

      event["tags"].each_with_index do |tag, j|
        return "Event #{i + 1}: tag #{j + 1} must be a string" unless tag.is_a?(String)
      end
    end

    nil
  end

  def valid_datetime?(str)
    str.match?(/\A\d{4}-\d{2}-\d{2} \d{2}:\d{2}\z/)
  end

  def find_venue_by_title(title)
    return nil if title.blank?

    # Try exact match first (case-insensitive)
    venue = Venue.where("LOWER(title) = ?", title.downcase).first
    return venue if venue

    # Try partial match (venue title contains search term or vice versa)
    Venue.where("LOWER(title) LIKE ?", "%#{title.downcase}%").first ||
      Venue.find { |v| title.downcase.include?(v.title.downcase) }
  end
end
