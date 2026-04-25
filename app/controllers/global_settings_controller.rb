class GlobalSettingsController < ApplicationController
  before_action :require_admin

  def toggle
    key = params[:key]
    current_value = GlobalSetting.get(key, "false") == "true"
    new_value = !current_value

    GlobalSetting.set(key, new_value ? "true" : "false")

    render json: {
      success: true,
      enabled: new_value,
      message: "#{params[:label]} is now #{new_value ? 'enabled' : 'disabled'}"
    }
  rescue => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  private

  def require_admin
    unless Current.user&.admin?
      render json: { error: "Access denied" }, status: :forbidden
    end
  end
end
