class TourCategory < ApplicationRecord
  has_many :tours, dependent: :restrict_with_exception
  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true
end
