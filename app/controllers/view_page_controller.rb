class ViewPageController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :require_admin_access

  def show
    slug = params[:slug]

    @page = Page.find_by(slug: slug)

    if @page
    else
      render status: 404
    end
  end


  def page_params
    params.require(:view_page).permit(:slug)
  end
end
