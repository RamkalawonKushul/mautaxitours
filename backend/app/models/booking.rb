class Booking < ApplicationRecord
  has_many :booking_items, dependent: :destroy
  has_many :payments, dependent: :restrict_with_exception
  has_many :operator_assignments, dependent: :restrict_with_error

  enum :status, { pending: "pending", confirmed: "confirmed", cancelled: "cancelled" }
  enum :payment_status, { unpaid: "unpaid", pending_payment: "pending_payment", paid: "paid", refunded: "refunded" }

  validates :reference, presence: true, uniqueness: true
  validates :customer_name, :customer_email, :travel_date, presence: true
  validates :customer_email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :idempotency_key, length: { minimum: 16, maximum: 128 }, allow_nil: true
  validates :total_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :currency, inclusion: { in: %w[MUR EUR USD GBP] }

  before_validation :assign_reference, on: :create

  private

  def assign_reference
    self.reference ||= "MT-#{SecureRandom.alphanumeric(8).upcase}"
  end
end
