module Api
  class SessionsController < BaseController
    skip_before_action :authenticate_api_user!, only: [ :create, :current ]

    def create
      user = User.find_by(email_address: params[:email_address])

      if user&.authenticate(params[:password]) && user.parser?
        user.regenerate_api_token!
        render json: {
          api_token: user.raw_api_token,
          email: user.email_address,
          role: user.role
        }, status: :ok
      elsif user&.authenticate(params[:password])
        render json: { error: "Access denied. Parser role required." }, status: :forbidden
      else
        render json: { error: "Invalid email or password" }, status: :unauthorized
      end
    end

    def current
      token = request.headers["Authorization"]&.split(" ")&.last

      if token.present?
        hashed = Digest::SHA256.hexdigest(token)
        user = User.find_by(api_token: hashed)

        if user&.parser?
          render json: {
            logged_in: true,
            user: {
              id: user.id,
              email: user.email_address,
              role: user.role
            }
          }, status: :ok
        elsif user
          render json: {
            logged_in: false,
            error: "Access denied. Parser role required."
          }, status: :forbidden
        else
          render json: {
            logged_in: false,
            error: "Invalid token"
          }, status: :unauthorized
        end
      else
        render json: {
          logged_in: false,
          error: "No token provided"
        }, status: :unauthorized
      end
    end
  end
end
