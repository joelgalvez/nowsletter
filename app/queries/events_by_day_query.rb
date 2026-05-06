class EventsByDayQuery
  def initialize(start_date: Date.today, days: 7, city: nil)
    @start_date = start_date
    @days = days
    @city = city
  end

  def call
    group_events_by_day(fetch_events)
  end

  private

  def fetch_events
    scope = Event
      .includes(:venue, :city, :tags)
      .from_date(@start_date.beginning_of_day)
      .until_date((@start_date + (@days - 1).days).end_of_day)
      .with_opted_in_venues
      .is_published
      .default_order(:asc)

    scope = scope.with_city(@city) if @city.present?
    scope.to_a
  end

  def group_events_by_day(all_events)
    days = []
    @days.times do |i|
      date = @start_date + i.days
      events = all_events.select { |event| event.start_date.to_date == date }
      days << { date: date, events: events } if events.any?
    end
    days
  end
end
