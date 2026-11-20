class Tour < ApplicationRecord
  belongs_to :tour_category, optional: true
  has_many :booking_items, dependent: :restrict_with_exception
  has_many :tour_vehicle_prices, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :adult_price_cents, :child_price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :currency, inclusion: { in: %w[MUR EUR USD GBP] }
  scope :published, -> { where(published: true) }
end
