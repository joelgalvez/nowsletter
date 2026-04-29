class City < ApplicationRecord
  belongs_to :country
  has_many :events

  scope :with_country_code, ->(country_code) {
    scope = where("TRUE")
    if country_code.present?
      scope = joins(:country).where(country: { country_code: country_code })
    else
      scope = where("FALSE")
    end
    scope
  }
  # scope :from_date, -> (date) { joins(:events).where('start_date > ? ', date).uniq }
  scope :from_date, ->(date) { joins(:events).where("start_date >= ?", date).or(joins(:events).where("end_date >= ?", date)).uniq }

  scope :with_list, ->(list) { joins(events: { venue: :lists }).where(events: { venue: { lists: list } }) }

  # New scope to filter by venues that have opted in
  scope :with_opted_in_venues, -> { joins(events: :venue).where(events: { venues: { opt_in: true, opt_out: false } }) }
  scope :with_not_opted_out_venues, -> { joins(events: :venue).where(events: { venues: { opt_out: false } }) }

  # New scope to filter by venues that have NOT opted in
  scope :with_opted_out_venues, -> { joins(events: :venue).where(events: { venues: { opt_in: [ false, nil ] } }) }

  scope :is_published, -> { joins(:events).where(events: { status: "published" }) }

  # scope :with_no_letter, -> { joins(:events).where(events: {letter: nil}) }

  scope :without_letter, ->(val) {
    scope = where("TRUE")
    if val
      scope = joins(:events).where(events: { letter: nil })
    end
    scope
  }
end
