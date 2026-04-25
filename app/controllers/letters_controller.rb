class LettersController < ApplicationController
  before_action :set_letter, only: %i[ show edit update destroy update_status body allow_this_and_future allow_future_only ]
  skip_before_action :require_admin_access, only: [ :body, :status ]
  skip_before_action :require_authentication, only: [ :status ]
  before_action :authorize_body_access, only: [ :body ]

  # GET /letters or /letters.json
  def index
    @query = params[:query]
    @sort = %w[subject status sent_date].include?(params[:sort]) ? params[:sort] : "sent_date"
    @direction = %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"

    @letters = Letter.all.order(Arel.sql("#{@sort} #{@direction}"))
    @letters = @letters.where("subject LIKE ?", "%#{@query}%") if @query.present?
    @letters = @letters.page(params[:page]).per(25)
  end

  # GET /letters/1 or /letters/1.json
  def show
  end

  # GET /letters/new
  def new
    @letter = Letter.new
    @venues = Venue.all.order(:title)
  end

  # GET /letters/1/edit
  def edit
    @venues = Venue.all.order(:title)
  end

  # POST /letters or /letters.json
  def create
    @letter = Letter.new(letter_params)

    respond_to do |format|
      if @letter.save
        format.html { redirect_to letter_url(@letter), notice: "Letter was successfully created." }
        format.json { render :show, status: :created, location: @letter }
      else
        @venues = Venue.all.order(:title)
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @letter.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /letters/1 or /letters/1.json
  def update
    respond_to do |format|
      if @letter.update(letter_params)
        format.html { redirect_to letter_url(@letter), notice: "Letter was successfully updated." }
        format.json { render :show, status: :ok, location: @letter }
      else
        @venues = Venue.all.order(:title)
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @letter.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /letters/1 or /letters/1.json
  def destroy
    ActiveRecord::Base.transaction do
      # Get all events for this letter
      event_ids = @letter.events.pluck(:id)

      # Clear all tag associations for these events
      if event_ids.any?
        conn = ActiveRecord::Base.connection
        quoted_ids = event_ids.map { |id| conn.quote(id) }.join(", ")
        conn.execute("DELETE FROM events_tags WHERE event_id IN (#{quoted_ids})")
      end

      # Nullify all logs that reference these events or this letter
      Log.where(event_id: event_ids).update_all(event_id: nil) if event_ids.any?
      Log.where(letter_id: @letter.id).update_all(letter_id: nil)

      # Now delete all events
      @letter.events.delete_all

      # Finally delete the letter
      @letter.destroy!
    end

    respond_to do |format|
      format.html { redirect_to letters_url }
      format.json { head :no_content }
    end
  rescue ActiveRecord::InvalidForeignKey => e
    Rails.logger.error "Failed to delete letter #{@letter.id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    respond_to do |format|
      format.html { redirect_to letters_url, alert: "Cannot delete letter: #{e.message}" }
      format.json { render json: { error: e.message }, status: :unprocessable_entity }
    end
  end

  # PATCH /letters/1/update_status
  def update_status
    new_status = params[:status]

    if new_status == "pending"
      @letter.create_llm_job
      success = true
    else
      success = @letter.update(status: new_status, pending_at: nil)
    end

    if success
      respond_to do |format|
        format.html { redirect_to letters_url, notice: "Status updated successfully." }
        format.json { render json: { status: @letter.status, pending_at: @letter.pending_at } }
      end
    else
      respond_to do |format|
        format.html { redirect_to letters_url, alert: "Failed to update status." }
        format.json { render json: { errors: @letter.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  # PATCH /letters/1/allow_this_and_future
  def allow_this_and_future
    @letter.venue.update!(checked: true)
    @letter.create_llm_job
    redirect_to letters_url
  end

  # PATCH /letters/1/allow_future_only
  def allow_future_only
    @letter.venue.update!(checked: true)
    @letter.update!(status: "ignored")
    redirect_to letters_url
  end

  # GET /letters/1/body
  def body
    render html: @letter.body.html_safe, layout: false
  end

  # GET /status
  def status
    has_pending = Letter.exists?(status: "pending")
    render json: { has_pending: has_pending }
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_letter
      @letter = Letter.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def letter_params
      params.require(:letter).permit(:from, :body, :uid, :subject, :json, :sent_date, :venue_id, :text_version)
    end

    # Authorize access to the body action
    def authorize_body_access
      return if Current.user&.admin?

      if Current.user&.editor?
        # Check if the letter belongs to the editor's venue
        unless @letter.venue == Current.user.venue
          respond_to do |format|
            format.html { redirect_to root_path, alert: "Access denied" }
            format.json { render json: { error: "Access denied" }, status: :forbidden }
          end
        end
      else
        respond_to do |format|
          format.html { redirect_to root_path, alert: "Access denied" }
          format.json { render json: { error: "Access denied" }, status: :forbidden }
        end
      end
    end
end
