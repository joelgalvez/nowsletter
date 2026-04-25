class SettingsController < ApplicationController
  before_action :set_setting, only: %i[ show edit update ]

  # GET /settings or /settings.json
  def index
    @query = params[:query]
    @sort = %w[name value created_at].include?(params[:sort]) ? params[:sort] : "name"
    @direction = %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"

    @settings = Setting.all.order(Arel.sql("#{@sort} #{@direction}"))
    @settings = @settings.where("name LIKE ? OR value LIKE ?", "%#{@query}%", "%#{@query}%") if @query.present?
    @settings = @settings.page(params[:page]).per(25)
  end

  # GET /settings/1 or /settings/1.json
  def show
  end

  # GET /settings/new
  def new
    @setting = Setting.new
  end

  # GET /settings/1/edit
  def edit
  end

  # POST /settings or /settings.json
  def create
    @setting = Setting.new(setting_params)

    respond_to do |format|
      if @setting.save
        format.html { redirect_to @setting, notice: "Setting was successfully created." }
        format.json { render :show, status: :created, location: @setting }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @setting.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /settings/1 or /settings/1.json
  def update
    respond_to do |format|
      if @setting.update(setting_params)
        format.html { redirect_to @setting, notice: "Setting was successfully updated." }
        format.json { render :show, status: :ok, location: @setting }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @setting.errors, status: :unprocessable_entity }
      end
    end
  end

  def test_system_notification
    LetterMailer.test_system_notification.deliver_now
    redirect_to settings_path, notice: "Test email sent to all admins."
  rescue => e
    redirect_to settings_path, alert: "Failed to send email: #{e.message}"
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_setting
      @setting = Setting.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def setting_params
      params.expect(setting: [ :name, :value, :description ])
    end
end
