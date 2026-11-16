class VehicleOption < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :capacity, numericality: { only_integer: true, greater_than: 0 }
  validates :upgrade_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  scope :active, -> { where(active: true).order(:capacity, :upgrade_cents) }
end
