class Tag < ApplicationRecord
  has_and_belongs_to_many :venues
  has_and_belongs_to_many :events

  scope :from_date, ->(date) { joins(:events).where("start_date > ? ", date) }

  scope :with_list, ->(list) { joins(events: { venue: :lists }).where(events: { venue: { lists: list } }) }

  # New scope to filter by venues that have opted in
  scope :with_opted_in_venues, -> { joins(events: :venue).where(events: { venues: { opt_in: true, opt_out: false } }) }
  scope :with_not_opted_out_venues, -> { joins(events: :venue).where(events: { venues: { opt_out: false } }) }

  # New scope to filter by venues that have NOT opted in
  scope :with_opted_out_venues, -> { joins(events: :venue).where(events: { venues: { opt_in: [ false, nil ] } }) }

  scope :with_no_letter, -> { joins(:events).where(events: { letter: nil }) }

  scope :is_published, -> { joins(:events).where(events: { status: "published" }) }

  scope :with_country_code, ->(country_code) {
    scope = where("TRUE")
    if country_code.present?
      scope = joins(events: { city: :country }).where(country: { country_code: country_code })
    else
      scope = where("TRUE")
    end
    scope
  }

  scope :with_city, ->(city) {
    scope = where("TRUE")
    if city.present?
      scope = joins(events: :city).where(city: { name: city })
    else
      scope = where("TRUE")
    end
    scope
  }

  scope :with_order, -> { order(count_cache: :desc).uniq }

  scope :without_letter, ->(val) {
    scope = where("TRUE")
    if val
      scope = joins(:events).where(events: { letter: nil })
    end
    scope
  }
end
