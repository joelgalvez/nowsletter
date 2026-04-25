class UsersController < ApplicationController
  before_action :require_admin_access
  before_action :set_user, only: [ :show, :edit, :update, :destroy ]

  def index
    @query = params[:query]
    @sort = %w[email_address role created_at].include?(params[:sort]) ? params[:sort] : "email_address"
    @direction = %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"

    @users = User.all.order(Arel.sql("#{@sort} #{@direction}"))
    @users = @users.where("email_address LIKE ?", "%#{@query}%") if @query.present?
    @users = @users.page(params[:page]).per(25)
  end

  def show
  end

  def new
    @user = User.new
  end

  def edit
  end

  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        if params[:redirect_to_venue].present?
          format.html {
            flash[:notice] = "User #{@user.email_address} was successfully created."
            redirect_to edit_venue_path(@user.venue)
          }
        else
          format.html { redirect_to users_path, notice: "User was successfully created." }
        end
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    # Don't update password if it's blank
    if params[:user][:password].blank? && params[:user][:password_confirmation].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end

    respond_to do |format|
      if @user.update(user_params)
        # Log the user update
        Log.create!(
          title: "User updated",
          text: "Updated user #{@user.email_address} - Role: #{@user.role}, Venue: #{@user.venue&.title}",
          venue: @user.venue,
          user: Current.user,
          role: "admin",
          severity: "normal"
        )

        if params[:redirect_to_venue].present?
          format.html {
            flash[:notice] = "User #{@user.email_address} was successfully updated."
            redirect_to edit_venue_path(@user.venue)
          }
        else
          format.html { redirect_to users_path, notice: "User was successfully updated." }
        end
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    venue = @user.venue
    email = @user.email_address
    @user.destroy!

    respond_to do |format|
      if params[:redirect_to_venue].present?
        format.html {
          flash[:notice] = "User #{email} was successfully removed."
          redirect_to edit_venue_path(venue)
        }
      else
        format.html { redirect_to users_path, notice: "User was successfully destroyed." }
      end
      format.json { head :no_content }
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    permitted = [ :email_address, :password, :password_confirmation, :venue_id ]
    permitted << :role if Current.user&.admin?
    params.require(:user).permit(*permitted)
  end

  def require_admin_access
    redirect_to root_path, alert: "Access denied" unless Current.user&.admin?
  end
end
