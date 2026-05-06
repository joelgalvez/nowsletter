class OngoingEventsQuery
  def initialize(city: nil)
    @city = city
  end

  def call
    fetch_events
  end

  private

  def fetch_events
    scope = Event
      .includes(:venue, :city, :tags, :letter)
      .ongoing
      .with_opted_in_venues
      .is_published
      .default_order(:asc)

    scope = scope.with_city(@city) if @city.present?
    scope.to_a
  end
end
