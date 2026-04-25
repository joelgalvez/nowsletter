class InterestingController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :require_admin_access
  skip_before_action :load_pages_for_sidebar
  skip_forgery_protection

  def script
    script_url = ENV["PLAUSIBLE_SCRIPT_URL"]
    return render plain: "", content_type: "application/javascript" if script_url.blank?

    response = Net::HTTP.get_response(URI(script_url))
    js = response.body.gsub("https://plausible.io/api/event", "/interesting/event")
    expires_in 1.day, public: true
    render plain: js, content_type: "application/javascript"
  end

  def event
    api_url = ENV["PLAUSIBLE_API_URL"]
    return head :no_content if api_url.blank?

    uri = URI(api_url)
    req = Net::HTTP::Post.new(uri)
    req["User-Agent"] = request.user_agent
    req["X-Forwarded-For"] = request.remote_ip
    req["Content-Type"] = "application/json"
    req.body = request.raw_post

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
    head res.code.to_i
  end
end
