class ApplicationController < ActionController::Base
  include Authentication
  include Authorization

  before_action :load_pages_for_sidebar

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  def load_pages_for_sidebar
    @pages = Page.all
  end

end
