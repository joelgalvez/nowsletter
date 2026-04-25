module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      set_current_user || reject_unauthorized_connection
    end

    private

    def set_current_user
      set_current_user_from_session || set_current_user_from_token
    end

    def set_current_user_from_session
      if session = Session.find_by(id: cookies.signed[:session_id])
        self.current_user = session.user
      end
    end

    def set_current_user_from_token
      token = request.params[:token]
      return unless token.present?
      hashed = Digest::SHA256.hexdigest(token)
      if user = User.find_by(api_token: hashed)
        self.current_user = user
      end
    end
  end
end
