class PaymentReconciliation
  Result = Struct.new(:payment_status, :verified_amount_cents, :outstanding_amount_cents, keyword_init: true)

  def self.call(booking:)
    verified_amount = booking.payments.verified.sum(:amount_cents)
    unresolved = booking.payments.where(status: %w[initiated awaiting_customer processing]).exists?
    refunded = booking.payments.where(status: "refunded").exists?

    next_status =
      if booking.total_cents.positive? && verified_amount >= booking.total_cents
        "paid"
      elsif verified_amount.positive? || unresolved
        "pending_payment"
      elsif refunded
        "refunded"
      else
        "unpaid"
      end

    booking.update!(payment_status: next_status) unless booking.payment_status == next_status

    Result.new(
      payment_status: booking.payment_status,
      verified_amount_cents: verified_amount,
      outstanding_amount_cents: (next_status == "refunded" ? 0 : [booking.total_cents - verified_amount, 0].max)
    )
  end
end
