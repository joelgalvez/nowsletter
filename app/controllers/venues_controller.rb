class VenuesController < ApplicationController
  skip_before_action :require_admin_access, only: [ :update, :search ]
  before_action :set_venue, only: %i[ edit update destroy ]
  # before_action :is_admin?, except: [:search]



  # GET /venues or /venues.json
  def index
    @query = params[:query]
    @sort = params[:sort] || "created_at"
    @direction = params[:direction] || "desc"

    # Whitelist allowed sort columns for security
    allowed_sort_columns = %w[title website created_at events_count]
    @sort = "created_at" unless allowed_sort_columns.include?(@sort)

    # Whitelist allowed directions
    allowed_directions = %w[asc desc]
    @direction = "desc" unless allowed_directions.include?(@direction)

    @venues = Venue.all

    # Special case for events_count which needs to be handled differently
    if @sort == "events_count"
      @venues = @venues.left_joins(:events)
                      .group(:id)
                      .order(Arel.sql("COUNT(events.id) #{@direction}"))
    else
      @venues = @venues.order(Arel.sql("#{@sort} #{@direction}"))
    end

    if @query.present?
      @venues = @venues.where("title LIKE ? OR website LIKE ?", "%#{@query}%", "%#{@query}%")
    end

    @venues = @venues.page(params[:page]).per(25)
  end

  # GET /venues/new
  def new
    @venue = Venue.new
    @tags = Tag.order(:title)
  end

  # GET /venues/1/edit
  def edit
    @senders = @venue.senders
    @new_sender = Sender.new(venue_id: @venue.id)
    @users = @venue.users
    @new_user = User.new(venue_id: @venue.id)
    @tags = Tag.order(:title)
  end

  # GET /venues/search.json
  def search
    query = params[:query].to_s.strip
    @venues = []

    if query.present? && query.length >= 2
      @venues = Venue.where("title LIKE ?", "%#{query}%")
                    .order(:title)
                    .limit(10)
    end

    render json: @venues.map { |v| { id: v.id, title: v.title } }
  end

  def delete_events_and_letters
    @venue = Venue.find(params[:id])
    @venue.events.destroy_all
    @venue.letters.destroy_all
    # redirect_to venue_url(@venue), notice: "Events and letters deleted."
    respond_to do |format|
      format.html { redirect_to @venue, notice: "Events and letters were successfully deleted." }
      format.json { head :no_content }
    end
  end

  # POST /venues or /venues.json
  def create
    @venue = Venue.new(venue_params)

    respond_to do |format|
      if @venue.save
        format.html { redirect_to venues_url, notice: "Venue was successfully created." }
        format.json { render :show, status: :created, location: @venue }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @venue.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /venues/1 or /venues/1.json
  def update
    # Check permissions: admins can update any venue, editors can only update their own
    unless Current.user.admin? || (Current.user.editor? && Current.user.venue_id == @venue.id)
      respond_to do |format|
        format.html { redirect_to root_path, alert: "You don't have permission to update this venue." }
        format.json { render json: { error: "Unauthorized" }, status: :unauthorized }
      end
      return
    end

    # Store the previous states for logging
    previous_opt_in = @venue.opt_in
    previous_accept_help = @venue.accept_help

    # For editors, only allow updating specific settings
    if Current.user.editor?
      # Only allow editors to update opt-in and accept_help settings
      filtered_params = params.require(:venue).permit(:opt_in, :accept_help)
    else
      # Admins can update all fields
      filtered_params = venue_params
    end

    respond_to do |format|
      if @venue.update(filtered_params)
        # Log opt-in status changes
        if filtered_params.key?(:opt_in) && previous_opt_in != @venue.opt_in
          log_setting_change("opt-in", previous_opt_in, @venue.opt_in)
        end

        # Log accept_help status changes
        if filtered_params.key?(:accept_help) && previous_accept_help != @venue.accept_help
          log_setting_change("accept help", previous_accept_help, @venue.accept_help)
        end

        format.html { redirect_to venue_url(@venue), notice: "Venue was successfully updated." }
        format.json { render :show, status: :ok, location: @venue }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @venue.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /venues/1 or /venues/1.json
  def destroy
    @venue.destroy!

    respond_to do |format|
      format.html { redirect_to venues_url, notice: "Venue was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_venue
      @venue = Venue.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def venue_params
      params.require(:venue).permit(:title, :website, :code, :opt_in, :accept_help, :checked, tag_ids: [])
    end

    # Log setting changes
    def log_setting_change(setting_name, previous_state, new_state)
      if setting_name == "opt-in"
        action = new_state ? "opted in" : "opted out"
        title = "Venue opt-in status changed"
      elsif setting_name == "accept help"
        action = new_state ? "enabled" : "disabled"
        title = "Venue accept help setting changed"
      else
        action = new_state ? "enabled" : "disabled"
        title = "Venue #{setting_name} setting changed"
      end

      previous_display = previous_state.nil? ? "unset" : previous_state.to_s

      Log.create!(
        venue: @venue,
        user: Current.user,
        title: title,
        text: "#{@venue.title}: #{setting_name} #{action}. Changed from #{previous_display} to #{new_state}",
        role: Current.user&.admin? ? "admin" : "editor",
        severity: "high"
      )
    end
end
