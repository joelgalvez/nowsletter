class Venue < ApplicationRecord
    has_and_belongs_to_many :tags
    has_many :senders
    has_many :users
    has_many :letters
    has_many :events
    belongs_to :city, optional: true

    has_and_belongs_to_many :lists

  before_validation :strip_website_protocol

  private

  def strip_website_protocol
    self.website = website.sub(/\Ahttps?:\/\//i, "").sub(/\/\z/, "") if website.present?
  end

  # scope :visible, -> { where(visible: 1) }
end
