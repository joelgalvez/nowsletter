class Event < ApplicationRecord
  belongs_to :letter, optional: true
  belongs_to :city, optional: true
  belongs_to :venue
  has_and_belongs_to_many :tags

  after_commit :cache_lead_image_if_changed, if: :should_cache_lead_image?

  scope :from_date, ->(date) { where("start_date >= ?", date) }
  scope :until_date, ->(date) { where("start_date <= ?", date) }

  # scope :with_tags, -> (tags) { joins(:tags).where(tags: {id: tags.ids}) }


  scope :with_country_code, ->(country_code) {
    scope = where("TRUE")
    if country_code.present?
      scope = joins(city: :country).where(country: { country_code: country_code })
    end
    scope
  }

  scope :with_city, ->(city) {
    scope = where("TRUE")
    if city.present?
      scope = joins(:city).where(city: { name: city })
    end
    scope
  }

  scope :with_tag, ->(tag) {
    scope = where("TRUE")
    if tag.present?
      scope = joins(:tags).where(tags: { title: tag })
    end
    scope
  }

  scope :with_venue, ->(venue) {
    scope = where("TRUE")
    if venue.present?
      scope = joins(:venue).where(venue: { id: venue.id })
    end
  }

  scope :with_letter, ->(letter) {
    scope = where("TRUE")
    if letter.present?
      scope = where(letter: letter)
    end
  }

  scope :has_letter, -> { where.not(letter_id: nil) }

scope :with_list, ->(list_id) { joins(venue: :lists).where(lists: { id: list_id }) }

  # New scope to filter events by venues that have opted in
  scope :with_opted_in_venues, -> { joins(:venue).where(venues: { opt_in: true, opt_out: false }) }
  scope :with_not_opted_in_venues, -> { joins(:venue).where(venues: { opt_in: false }) }
  scope :with_not_opted_out_venues, -> { joins(:venue).where(venues: { opt_out: false }) }

  # New scope to filter events by venues that have NOT opted in
  scope :with_opted_out_venues, -> { joins(:venue).where(venues: { opt_in: [ false, nil ] }) }

  scope :is_published, -> { where(status: "published") }


  scope :default_order, ->(dir = :asc) { order(start_date: dir) }
  scope :end_date_order, ->(dir = :asc) { order(end_date: dir) }



  # scope :visible, -> { joins(:venue).where(venue: {visible: 1}) }

  # scope :paginate, -> (limit, offset) { limit(limit).offset(offset) }


  def today?
    return false if start_date.nil?
    start_date >= Time.current.beginning_of_day && start_date < (Time.current.beginning_of_day + 1.day)
  end

  def tomorrow?
    return false if start_date.nil?
    start_date >= Time.current.tomorrow.beginning_of_day && start_date < (Time.current.tomorrow.beginning_of_day + 1.day)
  end

  def after_tomorrow?
    return false if start_date.nil?
    start_date >= (Time.current.beginning_of_day + 2.days) && start_date < (Time.current.beginning_of_day + 3.day)
  end

  def passed?
    return false if end_date.nil?
    end_date < Time.current.beginning_of_day
  end

  def display_lead_image
    lead_image_cached.presence || lead_image
  end

  def display_lead_image_thumbnail(width, height, absolute: false)
    img_url = display_lead_image
    return nil if img_url.blank?

    if img_url.start_with?("/cached_images/")
      ext = File.extname(img_url)
      thumbnail_path = img_url.gsub(/\/lead_image\//, "/thumbnails/").gsub(/(\.\w+)$/, "_#{width}x#{height}#{ext}")

      if absolute
        host = Rails.application.routes.default_url_options[:host]
        protocol = Rails.env.production? ? "https" : "http"
        "#{protocol}://#{host}#{thumbnail_path}"
      else
        thumbnail_path
      end
    else
      img_url
    end
  end

  # def passed?
  #   return false if start_date.nil?
  #   start_date.future? && start_date < 2.days.from_now
  # end
  #
  #
  # scope :from_now, -> { where('star')}
  # scope :country_code, -> { where('start_date >= ? ', Time.new).where(end_date: nil).or(where('end_date >= ?', Time.new)) }
  scope :not_ended, -> { where("start_date >= ? ", Time.current.beginning_of_day).where(end_date: nil).or(where("end_date >= ?", Time.current.beginning_of_day)) }
  scope :ongoing, -> { where("start_date < ?", Time.current).where("end_date >= ?", Time.current) }
  scope :from_now, -> { where("start_date > ?", Time.current) }

  private

  def should_cache_lead_image?
    saved_change_to_lead_image? && lead_image.present?
  end

  def cache_lead_image_if_changed
    # Clear the cached image immediately to avoid showing stale cached version
    # This ensures we show the new lead_image URL while caching is in progress
    update_column(:lead_image_cached, nil)

    # Queue the job asynchronously to avoid timing out HTTP requests
    # The display_lead_image method will fall back to lead_image until cached
    CacheEventLeadImageJob.perform_later(id)
  end
end
