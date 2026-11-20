class TourVehiclePrice < ApplicationRecord
  belongs_to :tour
  belongs_to :vehicle_option

  validates :price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :currency, inclusion: { in: %w[MUR EUR USD GBP] }
  validates :vehicle_option_id, uniqueness: { scope: :tour_id }

  scope :active, -> { where(active: true).joins(:vehicle_option).merge(VehicleOption.active).order("vehicle_options.capacity ASC") }
end
