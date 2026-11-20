class OperatorAssignment < ApplicationRecord
  belongs_to :booking
  belongs_to :operator

  STATUSES = %w[assigned sent accepted declined completed cancelled reassigned].freeze
  PAYMENT_STATUSES = %w[unpaid partially_paid paid].freeze

  validates :status, inclusion: { in: STATUSES }
  validates :payment_status, inclusion: { in: PAYMENT_STATUSES }
  validates :operator_cost_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :operator_paid_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :currency, format: { with: /\A[A-Z]{3}\z/ }
  validate :paid_amount_does_not_exceed_cost

  before_validation :normalise_currency
  before_validation :sync_payment_status
  before_validation :stamp_workflow_dates

  private

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
    return unless operator_paid_cents.to_i > operator_cost_cents.to_i

    errors.add(:operator_paid_cents, "cannot exceed the agreed operator cost")
  end
end
