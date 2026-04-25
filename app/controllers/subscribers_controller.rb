class SubscribersController < ApplicationController
  allow_unauthenticated_access only: [ :create, :confirm, :subscribe ]
  skip_before_action :require_admin_access, only: [ :create, :confirm, :subscribe ]

  def index
    @subscribers = Subscriber.includes(:user).order(created_at: :desc)
  end

  def subscribe
    @subscriber = Subscriber.new

    @ongoing_events = OngoingEventsQuery.new(city: "Amsterdam").call

    @days = EventsByDayQuery.new(days: 14, city: "Amsterdam").call
  end

  def destroy
    @subscriber = Subscriber.find(params[:id])
    @subscriber.destroy
    redirect_to subscribers_path, notice: "Subscriber deleted successfully."
  end

  def confirm
    @subscriber = Subscriber.find_by(confirmation_token: params[:token])

    if @subscriber.nil?
      @message = "Invalid confirmation link."
    elsif @subscriber.confirmed?
      @message = "Your subscription is already confirmed."
    else
      @subscriber.update(confirmed: true, confirmed_at: Time.current)
      @message = "Thank you! Your subscription has been confirmed."
    end

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("subscriber_form", partial: "subscribers/confirmed", locals: { message: @message }) }
      format.html { render :confirm }
    end
  end

  def create
    @subscriber = Subscriber.new(subscriber_params.except(:source))
    @from_subscribe_page = params[:subscriber][:source] == "subscribe_page"

    # Find or create user
    @user = User.find_by(email_address: subscriber_params[:email])

    if @user
      # User exists, check if already subscribed
      if @user.subscriber
        @subscriber.errors.add(:email, "is already subscribed")
        render turbo_stream: turbo_stream.replace("subscriber_form", partial: form_partial, locals: { subscriber: @subscriber })
        return
      end
      # User exists but not subscribed - keep their existing role, just add subscriber record
      # No need to update role
    else
      # Create new user with subscriber role
      @user = User.new(
        email_address: subscriber_params[:email],
        role: "subscriber",
        password: SecureRandom.hex(32)
      )

      unless @user.save
        @subscriber.valid?
        @user.errors.each do |error|
          @subscriber.errors.add(:email, error.message)
        end
        render turbo_stream: turbo_stream.replace("subscriber_form", partial: form_partial, locals: { subscriber: @subscriber })
        return
      end
    end

    # Connect subscriber to user
    @subscriber.user = @user
    if @subscriber.save
      SubscriberMailer.confirmation(@subscriber).deliver_later
      render turbo_stream: turbo_stream.replace("subscriber_form", partial: success_partial)
    else
      render turbo_stream: turbo_stream.replace("subscriber_form", partial: form_partial, locals: { subscriber: @subscriber })
    end
  end

  private

  def subscriber_params
    params.require(:subscriber).permit(:email, :comment, :source)
  end

  def form_partial
    @from_subscribe_page ? "subscribers/subscribe_form" : "subscribers/form"
  end

  def success_partial
    @from_subscribe_page ? "subscribers/subscribe_success" : "subscribers/success"
  end
end
