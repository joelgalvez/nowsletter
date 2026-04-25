module Api
  class BaseController < ActionController::API
    before_action :authenticate_api_user!

    private

    def authenticate_api_user!
      token = request.headers["Authorization"]&.split(" ")&.last

      if token.present?
        hashed = Digest::SHA256.hexdigest(token)
        @current_api_user = User.find_by(api_token: hashed)
      end

      unless @current_api_user&.parser?
        render json: { error: "Unauthorized. Parser role required." }, status: :unauthorized
      end
    end

    def current_api_user
      @current_api_user
    end
  end
end
