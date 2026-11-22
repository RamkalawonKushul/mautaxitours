class OperatorAssignment < ApplicationRecord
  belongs_to :booking, optional: true
  belongs_to :transport_enquiry, optional: true
  belongs_to :operator

  STATUSES = %w[assigned sent accepted declined completed cancelled reassigned].freeze
  PAYMENT_STATUSES = %w[unpaid partially_paid paid].freeze

  validates :status, inclusion: { in: STATUSES }
  validates :payment_status, inclusion: { in: PAYMENT_STATUSES }
  validates :operator_cost_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :operator_paid_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :customer_price_cents, numericality: { only_integer: true, greater_than: 0 }, if: :transport_enquiry_id?
  validates :currency, inclusion: { in: %w[MUR EUR USD GBP] }
  validate :currency_matches_booking
  validate :exactly_one_customer_request
  validate :paid_amount_does_not_exceed_cost

  before_validation :normalise_currency
  before_validation :sync_payment_status
  before_validation :stamp_workflow_dates

  private

  def currency_matches_booking
    return unless booking && currency.present?
    errors.add(:currency, "must match the booking currency") unless currency == booking.currency
  end

  def exactly_one_customer_request
    errors.add(:base, "An assignment must belong to exactly one booking or transfer enquiry") if booking_id.present? == transport_enquiry_id.present?
  end

  def normalise_currency
    self.currency = currency.to_s.upcase
  end

  def sync_payment_status
    self.payment_status =
      if operator_cost_cents.to_i.positive? && operator_paid_cents.to_i >= operator_cost_cents.to_i
        "paid"
      elsif operator_paid_cents.to_i.positive?
        "partially_paid"
      else
        "unpaid"
      end
  end

  def stamp_workflow_dates
    self.sent_at ||= Time.current if status == "sent"
    self.accepted_at ||= Time.current if status == "accepted"
    self.completed_at ||= Time.current if status == "completed"
  end

  def paid_amount_does_not_exceed_cost
    errors.add(:operator_paid_cents, "cannot exceed the agreed operator cost") if operator_paid_cents.to_i > operator_cost_cents.to_i
  end
end
