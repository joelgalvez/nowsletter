module Authorization
  extend ActiveSupport::Concern

  included do
    before_action :require_admin_access
    helper_method :current_user_admin?, :current_user_editor?, :current_user_parser?
  end

  class_methods do
    def allow_roles(*roles, **options)
      skip_before_action :require_admin_access, **options
      before_action -> { require_role_access(roles) }, **options
    end

    def allow_all_authenticated_users(**options)
      skip_before_action :require_admin_access, **options
    end
  end

  private

  def require_admin_access
    unless current_user_admin?
      respond_to do |format|
        format.html { redirect_to root_path, alert: "Admin access required" }
        format.json { render json: { error: "Admin access required" }, status: :forbidden }
      end
    end
  end

  def require_role_access(allowed_roles)
    unless user_has_any_role?(allowed_roles)
      respond_to do |format|
        format.html { redirect_to root_path, alert: "Access denied. Required roles: #{allowed_roles.join(', ')}" }
        format.json { render json: { error: "Access denied", required_roles: allowed_roles }, status: :forbidden }
      end
    end
  end

  def user_has_any_role?(roles)
    return false unless current_user

    roles = Array(roles).map(&:to_s)
    roles.include?(current_user.role) || (roles.include?("authenticated") && current_user.present?)
  end

  def current_user
    @current_user ||= Current.session&.user
  end

  def current_user_admin?
    current_user&.admin?
  end

  def current_user_editor?
    current_user&.editor?
  end

  def current_user_parser?
    current_user&.parser?
  end
end
