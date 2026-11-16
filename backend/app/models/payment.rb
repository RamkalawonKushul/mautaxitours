class Payment < ApplicationRecord
  belongs_to :booking

  enum :status, {
    initiated: "initiated",
    awaiting_customer: "awaiting_customer",
    processing: "processing",
    succeeded: "succeeded",
    failed: "failed",
    cancelled: "cancelled",
    refunded: "refunded"
  }

  validates :provider, inclusion: { in: %w[maubank] }
  validates :currency, inclusion: { in: %w[MUR EUR USD GBP] }
  validates :amount_cents, :base_amount_mur_cents,
            numericality: { only_integer: true, greater_than: 0 }
  validates :fx_rate_to_mur, numericality: { greater_than: 0 }
  validates :fx_quoted_at, :idempotency_key, presence: true
  validates :idempotency_key, uniqueness: true
  validates :provider_transaction_id, uniqueness: true, allow_nil: true
  validates :provider_payment_reference, uniqueness: true, allow_nil: true

  def successful?
    succeeded? && paid_at.present?
  end
end
