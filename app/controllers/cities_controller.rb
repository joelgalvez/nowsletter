class CitiesController < ApplicationController
  before_action :set_city, only: %i[ show edit update destroy ]
  skip_before_action :require_admin_access, only: [ :create_with_country ]

  # GET /cities or /cities.json
  def index
    @cities = City.all
  end

  # POST /cities/create_with_country
  def create_with_country
    # Only allow admins and editors to create cities
    unless Current.user&.admin? || Current.user&.editor?
      render json: { error: "Access denied" }, status: :forbidden
      return
    end

    country_code = params[:country_code]&.upcase
    city_name = params[:city_name]&.strip

    # Validate input
    if country_code.blank? || city_name.blank?
      render json: { error: "Country code and city name are required" }, status: :unprocessable_entity
      return
    end

    unless country_code.match?(/^[A-Z]{2}$/)
      render json: { error: "Invalid country code format" }, status: :unprocessable_entity
      return
    end

    # Find or create country
    country = Country.find_or_create_by(country_code: country_code)

    # Check if city already exists
    existing_city = City.find_by(country: country, name: city_name)
    if existing_city
      render json: { city_id: existing_city.id, message: "City already exists" }, status: :ok
      return
    end

    # Create new city
    city = City.new(country: country, name: city_name)

    if city.save
      render json: { city_id: city.id, message: "City created successfully" }, status: :created
    else
      render json: { error: city.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  # GET /cities/1 or /cities/1.json
  def show
  end

  # GET /cities/new
  def new
    @city = City.new
  end

  # GET /cities/1/edit
  def edit
  end

  # POST /cities or /cities.json
  def create
    @city = City.new(city_params)

    respond_to do |format|
      if @city.save
        format.html { redirect_to city_url(@city), notice: "City was successfully created." }
        format.json { render :show, status: :created, location: @city }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @city.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /cities/1 or /cities/1.json
  def update
    respond_to do |format|
      if @city.update(city_params)
        format.html { redirect_to city_url(@city), notice: "City was successfully updated." }
        format.json { render :show, status: :ok, location: @city }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @city.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /cities/1 or /cities/1.json
  def destroy
    @city.destroy!

    respond_to do |format|
      format.html { redirect_to cities_url, notice: "City was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_city
      @city = City.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def city_params
      params.require(:city).permit(:name, :country_id)
    end
end
