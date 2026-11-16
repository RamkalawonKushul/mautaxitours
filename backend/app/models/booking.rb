class Booking < ApplicationRecord
  has_many :booking_items, dependent: :destroy
  has_many :payments, dependent: :restrict_with_exception

  enum :status, { pending: "pending", confirmed: "confirmed", cancelled: "cancelled" }
  enum :payment_status, { unpaid: "unpaid", pending_payment: "pending_payment", paid: "paid", refunded: "refunded" }

  validates :reference, presence: true, uniqueness: true
  validates :customer_name, :customer_email, :travel_date, presence: true
  validates :total_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  before_validation :assign_reference, on: :create

  private

  def assign_reference
    self.reference ||= "MT-#{SecureRandom.alphanumeric(8).upcase}"
  end
end
