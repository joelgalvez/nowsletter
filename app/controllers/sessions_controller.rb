class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  skip_before_action :require_admin_access
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: "Try again later." }

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      # Update last dashboard visit on login
      user.update_column(:last_dashboard_visit, Time.current)

      # Create login log entry
      Log.create!(
        title: "User logged in",
        text: "Logged in via password",
        venue: user.venue,
        user: user,
        role: user.role || "editor",
        severity: "normal"
      )

      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: "Try another email address or password."
    end
  end

  def destroy
    # Create logout log entry before terminating session
    if Current.user
      Log.create!(
        title: "User logged out",
        text: "Logged out",
        venue: Current.user.venue,
        user: Current.user,
        role: Current.user.role || "editor",
        severity: "normal"
      )
    end

    terminate_session
    redirect_to new_session_path
  end
end
