class TransportEnquiry < ApplicationRecord
  enum :status, { new: "new", contacted: "contacted", quoted: "quoted", confirmed: "confirmed", cancelled: "cancelled" }

  validates :reference, presence: true, uniqueness: true
  validates :pickup_location, :destination, :travel_date, :pickup_time, presence: true
  validates :passengers, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 22 }

  before_validation :assign_reference, on: :create

  private

  def assign_reference
    self.reference ||= "TR-#{SecureRandom.alphanumeric(8).upcase}"
  end
end
