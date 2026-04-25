class BlacklistsController < ApplicationController
  skip_before_action :require_admin_access, only: [ :toggle ]
  before_action :require_editor_or_admin_for_toggle, only: [ :toggle ]
  before_action :set_blacklist, only: %i[ show edit update destroy ]

  # GET /blacklists or /blacklists.json
  def index
    @blacklists = Blacklist.all
  end

  # GET /blacklists/1 or /blacklists/1.json
  def show
  end

  # GET /blacklists/new
  def new
    @blacklist = Blacklist.new
  end

  # GET /blacklists/1/edit
  def edit
  end

  # POST /blacklists or /blacklists.json
  def create
    @blacklist = Blacklist.new(blacklist_params)

    respond_to do |format|
      if @blacklist.save
        format.html { redirect_to @blacklist, notice: "Blacklist was successfully created." }
        format.json { render :show, status: :created, location: @blacklist }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @blacklist.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /blacklists/1 or /blacklists/1.json
  def update
    respond_to do |format|
      if @blacklist.update(blacklist_params)
        format.html { redirect_to @blacklist, notice: "Blacklist was successfully updated." }
        format.json { render :show, status: :ok, location: @blacklist }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @blacklist.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /blacklists/1 or /blacklists/1.json
  def destroy
    @blacklist.destroy!

    respond_to do |format|
      format.html { redirect_to blacklists_path, status: :see_other, notice: "Blacklist was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  # POST /blacklists/toggle
  def toggle
    url = params[:url].to_s.strip
    letter = params[:letter_id].present? ? Letter.find_by(id: params[:letter_id]) : nil
    Rails.logger.info "[Blacklist#toggle] url=#{url.inspect} letter_id=#{letter&.id.inspect}"

    # Find existing blacklist entry
    blacklist = Blacklist.find_by(url: url)

    if blacklist
      # If exists, delete it (unblacklist)
      blacklist.destroy

      # Log the unblacklist action
      Log.create!(
        title: "Image Unblacklisted",
        text: "Unblacklisted image: #{url}",
        venue: Current.user.venue,
        user: Current.user,
        role: "editor",
        severity: "normal"
      )

      respond_to do |format|
        format.html { redirect_back(fallback_location: dashboard_path, notice: "Image unblacklisted.") }
        format.json { render json: { blacklisted: false, message: "Image unblacklisted" } }
      end
    else
      # If doesn't exist, create it (blacklist)
      Blacklist.create!(url: url)

      cleared_event_ids = []
      if letter && (Current.user&.admin? || Current.user&.venue_id == letter.venue_id)
        matching = letter.events.where("TRIM(lead_image) = ? OR TRIM(lead_image_cached) = ?", url, url)
        cleared_event_ids = matching.pluck(:id)
        Rails.logger.info "[Blacklist#toggle] letter=#{letter.id} matched events=#{cleared_event_ids.inspect}"
        if cleared_event_ids.any?
          Event.where(id: cleared_event_ids).update_all(lead_image: nil, lead_image_cached: nil)
        end
      end
      cleared_count = cleared_event_ids.size

      # Log the blacklist action
      Log.create!(
        title: "Image Blacklisted",
        text: "Blacklisted image: #{url}#{cleared_count.positive? ? " (cleared from #{cleared_count} event(s) in this letter)" : ""}",
        venue: Current.user.venue,
        user: Current.user,
        role: "editor",
        severity: "normal",
        letter: letter
      )

      cleared_event_cards = Event.where(id: cleared_event_ids).each_with_object({}) do |ev, h|
        h[ev.id] = render_to_string(partial: "dashboard/event_card", locals: { event: ev }, formats: [ :html ])
      end

      respond_to do |format|
        format.html { redirect_back(fallback_location: dashboard_path, notice: "Image blacklisted.") }
        format.json {
          render json: {
            blacklisted: true,
            message: "Image blacklisted",
            cleared_count: cleared_count,
            cleared_event_cards: cleared_event_cards
          }
        }
      end
    end
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_blacklist
      @blacklist = Blacklist.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def blacklist_params
      params.expect(blacklist: [ :url ])
    end

    # Allow editors and admins to toggle blacklist
    def require_editor_or_admin_for_toggle
      unless Current.user&.admin? || Current.user&.editor?
        render json: { error: "Access denied" }, status: :forbidden
      end
    end
end
