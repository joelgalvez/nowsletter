class List < ApplicationRecord
  has_and_belongs_to_many :venues
  has_many :messages
end
