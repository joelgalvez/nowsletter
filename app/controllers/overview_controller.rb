require "chronic"

class OverviewController < ApplicationController
  # Allow public access (no authentication required)
  allow_unauthenticated_access
  skip_before_action :require_admin_access
  before_action :require_authentication, only: [ :list ], if: :show_all_page?

  def index
    @text = "aa"
  end
  def list
    unless authenticated?
      expires_in 20.minutes, public: true
      response.headers["Vary"] = "Cookie"
    end

    country_code = params[:country_code] if params[:country_code].present?
    city = params[:city] if params[:city].present?
    tag = params[:tag] if params[:tag].present?
    # Determine if we're on the home page (no list_title) or /not/really page
    @use_opted_in = true  # Default to showing opted-in venues (home page)
    @show_all = false  # Flag for showing everything on /not/really

    if params[:list_title].present?
      # If list_title is "really", show ALL events (no filters)
      if params[:list_title] == "really"
        @show_all = true
      end
      # Keep the @list for backwards compatibility but it won't be used for filtering
      @list = List.find_by(title: params[:list_title])
    else
      # Home page - show opted-in venues
      @list = List.find_by(title: "Public")  # Keep for backwards compatibility
    end

    # Apply the opted-in/opted-out filter based on the page
    @eventsOngoing =  Event
                        .includes(:venue, :city, :tags)
                        .with_country_code(country_code)
                        .with_city(city)
                        .with_tag(tag)
                        .is_published
                        .with_opted_in_venues
                        .with_not_opted_out_venues

    @events =     Event
                        .includes(:venue, :city, :tags)
                        .with_country_code(country_code)
                        .from_date(Time.current.beginning_of_day)
                        .with_city(city)
                        .with_tag(tag)
                        .is_published
                        .with_opted_in_venues
                        .with_not_opted_out_venues


    # Apply the venue opt-in filter for home page
    if @use_opted_in
      @eventsOngoing = @eventsOngoing.with_opted_in_venues
      @events = @events.with_opted_in_venues
    end

    # Apply other common filters
    @eventsOngoing = @eventsOngoing
                        .not_ended
                        .has_letter
                        .ongoing
                        .is_published
                        .end_date_order(:asc)

    @events = @events
                        .not_ended
                        .has_letter
                        .is_published
                        .from_date(Time.current.beginning_of_day)
                        .default_order




    # Apply the opted-in/opted-out filter to countries, cities, and tags as well
    @countries =    Country
    @cities =       City.with_country_code(country_code)
    @tags =         Tag.with_country_code(country_code).with_city(city)

    if @show_all
      # /not/really - Show all (still hide opted-out venues)
      @countries = @countries.with_not_opted_out_venues.from_date(Time.current.beginning_of_day)
      @cities = @cities.with_not_opted_out_venues.from_date(Time.current.beginning_of_day)
      @tags = @tags.with_not_opted_out_venues.from_date(Time.current.beginning_of_day).with_order
    else
      # Apply venue opt-in filter
      if @use_opted_in
        @countries = @countries.with_opted_in_venues
        @cities = @cities.with_opted_in_venues
        @tags = @tags.with_opted_in_venues
      end

      @countries = @countries
                        .is_published
                        .from_date(Time.current.beginning_of_day)

      @cities = @cities
                        .is_published
                        .from_date(Time.current.beginning_of_day)

      @tags = @tags
                        .is_published
                        .from_date(Time.current.beginning_of_day)
                        .with_order
    end


    @allMessages = Message.all.order(:order)
  end

  def letter
    @letter = Letter.find(params[:id])
    @event = Event.find(params[:event_id])
    raise ActiveRecord::RecordNotFound if @letter.venue&.opt_out || @event.venue&.opt_out
  end
  def event
    @event = Event.find(params[:event_id])
    raise ActiveRecord::RecordNotFound if @event.venue&.opt_out
  end

  private

  def show_all_page?
    params[:list_title] == "really"
  end
end
