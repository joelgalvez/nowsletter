class OptOutsController < ApplicationController
  skip_before_action :require_admin_access
  skip_before_action :require_authentication, only: [ :show, :update ], if: :token_present?

  before_action :authenticate_with_token, only: [ :show, :update ]
  before_action :set_venue

  def show
  end

  def update
    if @venue
      new_value = ActiveModel::Type::Boolean.new.cast(params[:opt_out])
      @venue.update!(opt_out: new_value)

      Log.create!(
        title: new_value ? "Venue opted out" : "Venue opted back in",
        text: "#{@venue.title} #{new_value ? 'opted out' : 'opted back in'} via opt-out page",
        venue: @venue,
        user: Current.user,
        role: Current.user&.role || "editor",
        severity: "high"
      )

      LetterMailer.venue_opted_out(@venue).deliver_later if new_value

      redirect_to opt_out_path(token: params[:token]),
                  notice: new_value ? "#{@venue.title} has been opted out." : "#{@venue.title} has been opted back in."
    else
      redirect_to root_path, alert: "Access denied"
    end
  end

  private

  def token_present?
    params[:token].present?
  end

  def authenticate_with_token
    return if Current.user

    if params[:token].present?
      user = User.find_by(login_token: params[:token])
      if user && user.valid_login_token?(params[:token])
        start_new_session_for(user)
      end
    end
  end

  def set_venue
    @venue = Current.user&.venue
    redirect_to root_path, alert: "Access denied" unless @venue
  end
end
