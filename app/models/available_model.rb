class AvailableModel < ApplicationRecord
  validates :name, presence: true, uniqueness: true
end
