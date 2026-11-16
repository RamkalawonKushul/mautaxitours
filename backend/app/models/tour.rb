class Tour < ApplicationRecord
  belongs_to :tour_category, optional: true
  has_many :booking_items, dependent: :restrict_with_exception

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  scope :published, -> { where(published: true) }
end
