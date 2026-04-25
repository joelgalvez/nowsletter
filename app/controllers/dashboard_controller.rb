class DashboardController < ApplicationController
  skip_before_action :require_admin_access
  skip_before_action :require_authentication, only: [ :letter ], if: :token_present?
  before_action :authenticate_with_token, only: [ :letter ]

  def index
    if Current.user.admin?
      @venue = nil
      @letter = Letter.order(created_at: :desc).limit(1).first
    elsif Current.user.editor?
      @venue = Current.user.venue
      @letter = Letter.where(venue: @venue).order(created_at: :desc).limit(1).first
    end

    if @letter.present?
      redirect_params = {}
      redirect_params[:accept_help] = params[:accept_help] if params[:accept_help].present?
      redirect_params[:opt_in] = params[:opt_in] if params[:opt_in].present?
      redirect_to dashboard_letter_path(@letter.id, redirect_params)
    else
      # Render an empty dashboard view when no letters exist
      render :index
    end
  end

  def letter
    if Current.user.admin?
      @venue = nil
      @letter = Letter.find(params[:letter_id])
      @letters = Letter.order(created_at: :desc)
    elsif Current.user.editor?
      @venue = Current.user.venue
      # Only allow access to letters from user's venue
      @letter = Letter.where(venue: @venue).find_by(id: params[:letter_id])
      unless @letter
        redirect_to root_path, alert: "Access denied"
        return
      end
      @letters = Letter.where(venue: @venue).order(created_at: :desc)
    else
      redirect_to root_path, alert: "Access denied"
      return
    end

    # Handle accept_help parameter if present
    if params[:accept_help] == "1" && @letter.venue
      @letter.venue.update!(accept_help: true)
      flash.now[:notice] = "Accept help has been enabled for #{@letter.venue.title}"
    end

    # Handle opt_in parameter if present
    if params[:opt_in] == "1" && @letter.venue
      @letter.venue.update!(opt_in: true)
      flash.now[:notice] = "Opted in for #{@letter.venue.title}"
    end

    @events = Event
      .end_date_order(:asc)
      .with_letter(@letter)

    # Extract images from the letter's text version for blacklisting
    text_version = @letter.text_version
    @images = text_version.to_s.scan(/\[img\](.*?)\[\/img\]/m).flatten.map(&:strip)

    if Current.user.admin?
      @logs = Log.where(letter: @letter).order(created_at: :desc).limit(100)
    elsif Current.user.editor?
      @logs = Log.where(letter: @letter, role: "editor").order(created_at: :desc).limit(100)
    end
  end

  def new_event
    @letter = Letter.find(params[:letter_id])
    @event = Event.new(letter: @letter, venue: @letter.venue)

    text_version = @letter.text_version

    # extract an array of images from the text version between [img] [/img] tags
    @images = text_version.to_s.scan(/\[img\](.*?)\[\/img\]/m).flatten.map(&:strip)

    # Load cities with their countries for the dropdown
    @cities = City.includes(:country).order("countries.country_code, cities.name")

    # Load all valid countries for the country dropdown
    @all_countries = Country::ALL_COUNTRY_CODES

    if Current.user.admin? || (Current.user.editor? && @letter.venue == Current.user.venue)
      render "events/new"
    else
      redirect_to root_path, alert: "Access denied"
    end
  end

  def edit_event
    @event = Event.find(params[:event_id])

    text_version = @event.letter.text_version

    # extract an array of images from the text version between [img] [/img] tags
    @images = text_version.to_s.scan(/\[img\](.*?)\[\/img\]/m).flatten.map(&:strip)

    # Load cities with their countries for the dropdown
    @cities = City.includes(:country).order("countries.country_code, cities.name")

    # Load all valid countries for the country dropdown
    @all_countries = Country::ALL_COUNTRY_CODES

    if Current.user.admin? || (Current.user.editor? && @event.letter.venue == Current.user.venue)
      render "events/edit"
    else
      redirect_to root_path, alert: "Access denied"
    end
  end

  def publish_all
    @letter = Letter.find(params[:letter_id])

    # Check permissions
    if Current.user.admin? || (Current.user.editor? && @letter.venue == Current.user.venue)
      Event.with_letter(@letter).update_all(status: "published")

      # Log the action
      Log.create!(
        title: "Published All Events",
        text: "Published all events",
        venue: @letter.venue,
        user: Current.user,
        role: "editor",
        severity: "normal",
        letter: @letter
      )

      redirect_to dashboard_letter_path(@letter), notice: "All events have been published."
    else
      redirect_to root_path, alert: "Access denied"
    end
  end

  def unpublish_all
    @letter = Letter.find(params[:letter_id])

    # Check permissions
    if Current.user.admin? || (Current.user.editor? && @letter.venue == Current.user.venue)
      Event.with_letter(@letter).update_all(status: nil)

      # Log the action
      Log.create!(
        title: "Unpublished All Events",
        text: "Unpublished all events",
        venue: @letter.venue,
        user: Current.user,
        role: "editor",
        severity: "normal",
        letter: @letter
      )

      redirect_to dashboard_letter_path(@letter), notice: "All events have been unpublished."
    else
      redirect_to root_path, alert: "Access denied"
    end
  end

  def search_tags
    # Allow both admin and editor to search tags
    unless Current.user&.admin? || Current.user&.editor?
      render json: { error: "Access denied" }, status: :forbidden
      return
    end

    query = params[:q].to_s.strip.downcase

    if query.length >= 2
      tags = Tag.where("LOWER(title) LIKE ?", "%#{query}%")
                .order(:title)
                .limit(20)

      render json: tags.map { |tag| { id: tag.id, title: tag.title } }
    else
      render json: []
    end
  end



  def send_custom_template
    @letter = Letter.find(params[:letter_id])

    unless Current.user.admin?
      redirect_to root_path, alert: "Access denied"
      return
    end

    body = params[:body].to_s
    editors = User.where(venue: @letter.venue, role: "editor").where.not(email_address: nil)

    if editors.empty?
      redirect_to dashboard_letter_path(@letter), alert: "No editors found for #{@letter.venue.title}"
      return
    end

    # In test mode, deliver every message to the admin instead — but keep
    # each editor's own login token in the email body.
    test_mode = GlobalSetting.test_mode?
    test_to = test_mode ? (User.find_by(role: "admin") || User.first)&.email_address : nil

    subject = "Update for #{@letter.venue.title}"
    editors.each do |editor|
      LetterMailer.custom_template(@letter, editor, body: body, subject: subject, to: test_to).deliver_later
    end

    @letter.venue.increment!(:emails_sent_count)

    test_prefix = GlobalSetting.test_mode? ? "(TEST) " : ""
    Log.create!(
      title: "#{test_prefix}Custom Email Template Sent to Venue Editors",
      text: "Sent custom email to #{editors.size} editors of #{@letter.venue.title}",
      venue: @letter.venue,
      user: Current.user,
      role: "admin",
      severity: "high",
      letter: @letter
    )

    redirect_to dashboard_letter_path(@letter), notice: "Email sent to #{editors.size} editors of #{@letter.venue.title}"
  end

  def delete_all_events
    @letter = Letter.find(params[:letter_id])

    # Check permissions - only admins can delete all events
    if Current.user.admin?
      # Count events before deletion for logging
      event_count = @letter.events.count

      # Clear all associations before deleting events
      @letter.events.each do |event|
        # Clear the tags association (events_tags join table)
        event.tags.clear
        # Clear any logs that reference this event
        Log.where(event_id: event.id).update_all(event_id: nil)
      end

      # Now safely delete all events
      @letter.events.destroy_all

      @letter.create_llm_job

      Log.create!(
        title: "All Events Deleted",
        text: "Deleted #{event_count} events and requeued for processing",
        venue: @letter.venue,
        user: Current.user,
        role: "admin",
        severity: "high",
        letter: @letter
      )

      redirect_to dashboard_letter_path(@letter)
    else
      redirect_to root_path, alert: "Access denied"
    end
  end

  private

  def token_present?
    params[:token].present?
  end

  def authenticate_with_token
    if params[:token].present?
      user = User.find_by(login_token: params[:token])

      if user && user.valid_login_token?(params[:token])
        # Start a new session for this user
        start_new_session_for(user)
        # Update last dashboard visit on login
        user.update_column(:last_dashboard_visit, Time.current)

        # Create login log entry for token login
        Log.create!(
          title: "User logged in",
          text: "Logged in via email link",
          venue: user.venue,
          user: user,
          role: user.role || "editor",
          severity: "normal",
          letter_id: params[:letter_id]
        )

        # Don't clear the token - let it remain valid until expiry
        # Remove token from URL by redirecting, but preserve accept_help and opt_in parameters
        redirect_params = {}
        redirect_params[:accept_help] = params[:accept_help] if params[:accept_help].present?
        redirect_params[:opt_in] = params[:opt_in] if params[:opt_in].present?
        redirect_to dashboard_letter_path(params[:letter_id], redirect_params)
        return
      else
        # Invalid or expired token
        redirect_to new_session_path, alert: "Invalid or expired login link. Please sign in."
        return
      end
    end

    # If no token, ensure user is authenticated through normal flow
    require_authentication
  end
end
