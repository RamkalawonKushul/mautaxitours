class BookingItem < ApplicationRecord
  belongs_to :booking
  belongs_to :tour
  belongs_to :vehicle_option, optional: true

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price_cents, :line_total_cents, :transport_cents, :vehicle_upgrade_cents, :activity_cents,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :adults, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :children, :babies, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
