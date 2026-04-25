class SendersController < ApplicationController
  before_action :set_sender, only: %i[ show edit update destroy ]

  # GET /senders or /senders.json
  def index
    @query = params[:query]
    @sort = params[:sort] || "created_at"
    @direction = params[:direction] || "desc"

    # Whitelist allowed sort columns for security
    allowed_sort_columns = %w[email created_at]
    @sort = "created_at" unless allowed_sort_columns.include?(@sort)

    # Whitelist allowed directions
    allowed_directions = %w[asc desc]
    @direction = "desc" unless allowed_directions.include?(@direction)

    @senders = Sender.includes(:venue).order(Arel.sql("#{@sort} #{@direction}"))

    @senders = @senders.where("email LIKE ?", "%#{@query}%") if @query.present?

    @senders = @senders.page(params[:page]).per(15)
  end

  # GET /senders/1 or /senders/1.json
  def show
  end

  # GET /senders/new
  def new
    @sender = Sender.new
  end

  # GET /senders/1/edit
  def edit
  end

  # POST /senders or /senders.json
  def create
    @sender = Sender.new(sender_params)

    respond_to do |format|
      if @sender.save
        # If this was an inline creation from venue form
        if params[:redirect_to_venue].present?
          format.html { redirect_to edit_venue_path(@sender.venue), notice: "Sender was successfully created." }
        else
          format.html { redirect_to sender_url(@sender), notice: "Sender was successfully created." }
        end
        format.json { render :show, status: :created, location: @sender }
        format.turbo_stream { flash.now[:notice] = "Sender was successfully created." }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @sender.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /senders/1 or /senders/1.json
  def update
    respond_to do |format|
      if @sender.update(sender_params)
        # If this was an inline update from venue form
        if params[:redirect_to_venue].present?
          format.html {
            flash[:notice] = "Sender #{@sender.email} was successfully updated."
            redirect_to edit_venue_path(@sender.venue)
          }
        else
          format.html { redirect_to sender_url(@sender), notice: "Sender was successfully updated." }
        end
        format.json { render :show, status: :ok, location: @sender }
        format.turbo_stream { flash.now[:notice] = "Sender was successfully updated." }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @sender.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /senders/1 or /senders/1.json
  def destroy
    venue = @sender.venue
    @sender.destroy!

    respond_to do |format|
      if params[:redirect_to_venue].present?
        format.html {
          flash[:notice] = "Sender was successfully removed."
          redirect_to edit_venue_path(venue)
        }
      else
        format.html { redirect_to senders_url, notice: "Sender was successfully destroyed." }
      end
      format.json { head :no_content }
      format.turbo_stream { flash.now[:notice] = "Sender was successfully removed." }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_sender
      @sender = Sender.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def sender_params
      params.require(:sender).permit(:email, :venue_id)
    end
end
