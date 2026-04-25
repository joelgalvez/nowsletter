class EventsController < ApplicationController
  skip_before_action :require_admin_access
  before_action :require_editor_or_admin_access
  before_action :require_admin_access, only: %i[ unpublish ]
  before_action :set_event, only: %i[ show edit update destroy toggle_status unpublish remove_image blacklist_image ]
  before_action :authorize_event_access, only: %i[ show edit update destroy toggle_status unpublish remove_image blacklist_image ]

  # GET /events or /events.json
  def index
    events = scoped_events
    @venues = Venue.joins(letters: :events).merge(events).distinct.order(:title)
    events = events.where(venue_id: params[:venue_id]) if params[:venue_id].present?

    today = Time.current.beginning_of_day
    @upcoming_events = events.where("end_date >= ? OR (end_date IS NULL AND start_date >= ?)", today, today).order(start_date: :asc).page(params[:upcoming_page])
    @past_events = events.where("end_date < ? OR (end_date IS NULL AND start_date < ?)", today, today).order(start_date: :desc).page(params[:past_page])
  end

  # GET /events/1 or /events/1.json
  def show
  end

  # GET /events/new
  def new
    @event = Event.new
  end

  # GET /events/1/edit
  def edit
  end

  # POST /events or /events.json
  def create
    # Handle "new" city selection (user selected "Add new city" but didn't create one)
    if params[:event][:city_id] == "new"
      params[:event][:city_id] = nil
    end

    @event = Event.new(event_params)

    respond_to do |format|
      if @event.save
        # Log the event creation
        Log.create!(
          title: "Event Created",
          text: "Created event: #{@event.title}",
          venue: @event.venue,
          user: Current.user,
          role: Current.user.role || "editor",
          severity: "normal",
          letter: @event.letter,
          event: @event
        )

        if request.referer&.include?("/dashboard")
          format.turbo_stream {
            render turbo_stream: [
              turbo_stream.append("events_list", partial: "dashboard/event_card", locals: { event: @event }),
              turbo_stream.update("event_modal", "")
            ]
          }
          format.html { redirect_to dashboard_letter_path(@event.letter_id), notice: "Event was successfully created." }
        else
          format.html { redirect_to event_url(@event), notice: "Event was successfully created." }
        end
        format.json { render :show, status: :created, location: @event }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /events/1 or /events/1.json
  def update
    # Handle new tag creation
    handle_new_tags if params[:event][:new_tag_titles].present?

    # Handle "new" city selection (user selected "Add new city" but didn't create one)
    if params[:event][:city_id] == "new"
      params[:event][:city_id] = nil
    end

    # Track what changed before updating
    changed_attributes = []

    # Track tag changes
    old_tag_ids = @event.tag_ids.sort
    new_tag_ids = (params[:event][:tag_ids] || []).map(&:to_i).reject(&:zero?).sort

    if old_tag_ids != new_tag_ids
      old_tags = Tag.where(id: old_tag_ids).pluck(:title).sort
      new_tags = Tag.where(id: new_tag_ids).pluck(:title).sort

      if old_tags.empty?
        changed_attributes << "Tags added: #{new_tags.join(', ')}"
      elsif new_tags.empty?
        changed_attributes << "Tags removed: all tags"
      else
        changed_attributes << "Tags: [#{old_tags.join(', ')}] → [#{new_tags.join(', ')}]"
      end
    end

    # Track other attribute changes
    event_params.except(:tag_ids).each do |key, value|
      old_value = @event.attributes[key.to_s]

      # Special handling for date comparisons
      if key.to_s == "start_date" || key.to_s == "end_date"
        # Parse both values to DateTime for proper comparison
        begin
          old_date = old_value.present? ? Time.zone.parse(old_value.to_s) : nil
          new_date = value.present? ? Time.zone.parse(value.to_s) : nil

          # Only log if dates are actually different (compare as strings to avoid sub-second differences)
          old_str = old_date&.strftime("%Y-%m-%d %H:%M")
          new_str = new_date&.strftime("%Y-%m-%d %H:%M")

          if old_str != new_str
            old_formatted = old_date ? old_date.strftime("%b %d, %Y %I:%M %p") : "none"
            new_formatted = new_date ? new_date.strftime("%b %d, %Y %I:%M %p") : "none"
            changed_attributes << "#{key.to_s.humanize}: #{old_formatted} → #{new_formatted}"
          end
        rescue ArgumentError
          # If parsing fails, skip this comparison
        end
      elsif key.to_s == "city_id"
        # Special handling for city changes
        old_city_id = old_value.to_i if old_value.present?
        new_city_id = value.to_i if value.present?

        if old_city_id != new_city_id
          old_city = old_city_id ? City.includes(:country).find_by(id: old_city_id) : nil
          new_city = new_city_id ? City.includes(:country).find_by(id: new_city_id) : nil

          old_city_name = old_city ? "#{old_city.country.country_code} - #{old_city.name}" : "none"
          new_city_name = new_city ? "#{new_city.country.country_code} - #{new_city.name}" : "none"

          changed_attributes << "City: #{old_city_name} → #{new_city_name}"
        end
      elsif key.to_s == "letter_id"
        # Special handling for letter_id - compare as integers
        old_letter_id = old_value.to_i if old_value.present?
        new_letter_id = value.to_i if value.present?

        if old_letter_id != new_letter_id
          changed_attributes << "Letter changed"
        end
      elsif key.to_s == "venue_id"
        # Special handling for venue_id - compare as integers
        old_venue_id = old_value.to_i if old_value.present?
        new_venue_id = value.to_i if value.present?

        if old_venue_id != new_venue_id
          changed_attributes << "Venue changed"
        end
      elsif values_changed?(old_value, value)
        # Format the change description based on the field
        case key.to_s
        when "title"
          changed_attributes << "Title: '#{old_value}' → '#{value}'"
        when "text"
          changed_attributes << "Description updated"
        when "lead_image"
          changed_attributes << "Lead image changed"
        else
          changed_attributes << "#{key.to_s.humanize} changed"
        end
      end
    end

    respond_to do |format|
      if @event.update(event_params)
        # Log the event update with details of what changed, including current tags if they changed
        current_tags = @event.tags.pluck(:title).sort
        tags_changed = changed_attributes.any? { |attr| attr.start_with?("Tags") }

        changes_text = if changed_attributes.any?
          text = "#{changed_attributes.join("\n")}"
          text += "\nCurrent tags: [#{current_tags.join(', ')}]" if tags_changed && current_tags.any?
          text
        else
          text = "(no field changes detected)"
          text
        end

        Log.create!(
          title: "Event Updated",
          text: changes_text,
          venue: @event.letter.venue,
          user: Current.user,
          role: "editor",
          severity: "normal",
          letter: @event.letter,
          event: @event
        )

        if request.referer&.include?("/dashboard")
          format.turbo_stream {
            render turbo_stream: [
              turbo_stream.replace("event-#{@event.id}", partial: "dashboard/event_card", locals: { event: @event }),
              turbo_stream.update("event_modal", "")
            ]
          }
          format.html { redirect_to dashboard_letter_path(@event.letter_id), notice: "Event was successfully updated." }
        else
          format.html { redirect_to event_url(@event), notice: "Event was successfully updated." }
        end
        format.json { render :show, status: :ok, location: @event }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /events/1 or /events/1.json
  def destroy
    @event.destroy!

    respond_to do |format|
      format.html { redirect_to events_url, notice: "Event was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def toggle_status
    if @event.status == "published"
      @event.update(status: nil)
      action_text = "unpublished"
    else
      @event.update(status: "published")
      action_text = "published"
    end

    # Log the status toggle
    Log.create!(
      title: "Event Status Changed",
      text: "#{action_text.capitalize} event: #{@event.title}",
      venue: @event.letter.venue,
      user: Current.user,
      role: "editor",
      severity: "normal",
      letter: @event.letter,
      event: @event
    )

    respond_to do |format|
      format.html { redirect_back(fallback_location: dashboard_path, notice: "Event status updated.") }
      format.json { render json: { status: @event.status, success: true } }
    end
  end

  def remove_image
    old_url = @event.lead_image
    @event.update(lead_image: nil)

    Log.create!(
      title: "Event Lead Image Removed",
      text: "Removed lead image from event: #{@event.title} (was: #{old_url})",
      venue: @event.letter.venue,
      user: Current.user,
      role: "editor",
      severity: "normal",
      letter: @event.letter,
      event: @event
    )

    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace("event-#{@event.id}", partial: "dashboard/event_card", locals: { event: @event })
      }
      format.html { redirect_back(fallback_location: dashboard_path, notice: "Lead image removed.") }
      format.json { head :no_content }
    end
  end

  def blacklist_image
    url = @event.lead_image.to_s.strip
    letter = @event.letter

    if url.present? && !Blacklist.exists?(url: url)
      Blacklist.create!(url: url)
      Log.create!(
        title: "Image Blacklisted",
        text: "Blacklisted image: #{url}",
        venue: letter.venue,
        user: Current.user,
        role: "editor",
        severity: "normal",
        letter: letter,
        event: @event
      )
    end

    # Clear the lead image from EVERY event in this letter that uses the same URL,
    # not just the clicked event.
    affected_events = letter.events.where("TRIM(lead_image) = ? OR TRIM(lead_image_cached) = ?", url, url).to_a
    affected_event_ids = affected_events.map(&:id)
    if affected_event_ids.any?
      Event.where(id: affected_event_ids).update_all(lead_image: nil, lead_image_cached: nil)
    end
    # Always include the clicked event in the response, even if it wasn't matched (defensive)
    affected_event_ids |= [ @event.id ]
    @event.reload

    letter_images = letter.text_version.to_s.scan(/\[img\](.*?)\[\/img\]/m).flatten.map(&:strip)

    respond_to do |format|
      format.turbo_stream {
        streams = Event.where(id: affected_event_ids).map do |ev|
          turbo_stream.replace("event-#{ev.id}", partial: "dashboard/event_card", locals: { event: ev })
        end
        streams << turbo_stream.replace("image_blacklist_section", partial: "dashboard/image_blacklist", locals: { images: letter_images, letter: letter })
        render turbo_stream: streams
      }
      format.html { redirect_back(fallback_location: dashboard_path, notice: "Image blacklisted.") }
      format.json { head :no_content }
    end
  end

  def unpublish
    @event.update(status: nil)

    Log.create!(
      title: "Event Unpublished",
      text: "Unpublished event: #{@event.title}",
      venue: @event.letter.venue,
      user: Current.user,
      role: "editor",
      severity: "normal",
      letter: @event.letter,
      event: @event
    )

    respond_to do |format|
      format.html { redirect_back(fallback_location: dashboard_path, notice: "Event unpublished.") }
      format.json { render json: { status: @event.status, success: true } }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = Event.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def event_params
      params.require(:event).permit(:start_date, :end_date, :title, :text, :lead_image, :letter_id, :venue_id, :city_id, tag_ids: [])
    end

    # Handle creation of new tags
    def handle_new_tags
      new_tag_titles = params[:event][:new_tag_titles]
      return unless new_tag_titles.present?

      # Get or create tags for each new title
      new_tag_titles.each do |title|
        next if title.blank?

        # Find or create the tag (force lowercase)
        tag = Tag.find_or_create_by(title: title.strip.downcase)

        # Add the new tag ID to the tag_ids parameter
        params[:event][:tag_ids] ||= []
        params[:event][:tag_ids] << tag.id.to_s unless params[:event][:tag_ids].include?(tag.id.to_s)
      end

      # Remove the new_tag_titles parameter as it's not part of the model
      params[:event].delete(:new_tag_titles)
    end

    # Require editor or admin access
    def require_editor_or_admin_access
      unless Current.user&.admin? || Current.user&.editor?
        redirect_to root_path, alert: "Access denied"
      end
    end

    # Scope events based on user role
    def scoped_events
      if Current.user.admin?
        Event.all
      elsif Current.user.editor?
        Event.joins(:letter).where(letters: { venue_id: Current.user.venue_id })
      else
        Event.none
      end
    end

    # Authorize access to specific event
    def authorize_event_access
      if Current.user.editor? && @event.letter.venue != Current.user.venue
        redirect_to events_path, alert: "Access denied"
      end
    end

    # Compare values properly, handling type differences and nil/empty
    def values_changed?(old_value, new_value)
      # Normalize both values for comparison
      old_normalized = normalize_value(old_value)
      new_normalized = normalize_value(new_value)

      old_normalized != new_normalized
    end

    # Normalize values for comparison
    def normalize_value(value)
      return nil if value.nil? || value == ""
      return value.strip if value.is_a?(String)
      value
    end
end
