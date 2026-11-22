require "test_helper"

class PaymentReconciliationTest < ActiveSupport::TestCase
  setup do
    @booking = Booking.create!(
      customer_name: "Reconciliation Guest",
      customer_email: "reconcile@example.com",
      travel_date: Date.current + 2.days,
      total_cents: 12_500,
      currency: "EUR"
    )
  end

  test "a booking without a verified payment remains unpaid" do
    result = PaymentReconciliation.call(booking: @booking)

    assert_equal "unpaid", result.payment_status
    assert_equal 0, result.verified_amount_cents
    assert_equal 12_500, result.outstanding_amount_cents
    assert_equal "pending", @booking.reload.status
  end

  test "partial verified payments remain pending until the full booking total is received" do
    create_payment(amount_cents: 5_000, key: "reconcile-partial-0001")
    result = PaymentReconciliation.call(booking: @booking)

    assert_equal "pending_payment", result.payment_status
    assert_equal 5_000, result.verified_amount_cents
    assert_equal 7_500, result.outstanding_amount_cents

    create_payment(amount_cents: 7_500, key: "reconcile-final-0001")
    result = PaymentReconciliation.call(booking: @booking)

    assert_equal "paid", result.payment_status
    assert_equal 12_500, result.verified_amount_cents
    assert_equal 0, result.outstanding_amount_cents
    assert_equal "pending", @booking.reload.status
  end

  test "an unresolved payment does not count as collected money" do
    create_payment(amount_cents: 12_500, status: "initiated", key: "reconcile-open-0001")
    result = PaymentReconciliation.call(booking: @booking)

    assert_equal "pending_payment", result.payment_status
    assert_equal 0, result.verified_amount_cents
    assert_equal 12_500, result.outstanding_amount_cents
  end

  test "a fully refunded booking is marked refunded rather than paid" do
    create_payment(amount_cents: 12_500, status: "refunded", key: "reconcile-refund-0001")
    result = PaymentReconciliation.call(booking: @booking)

    assert_equal "refunded", result.payment_status
    assert_equal 0, result.verified_amount_cents
    assert_equal 0, result.outstanding_amount_cents
  end

  private

  def create_payment(amount_cents:, status: "succeeded", key:)
    Payment.create!(
      booking: @booking,
      provider: "sbm",
      status: status,
      currency: @booking.currency,
      amount_cents: amount_cents,
      base_amount_mur_cents: amount_cents * 50,
      fx_rate_to_mur: 50,
      fx_quoted_at: Time.current,
      idempotency_key: key,
      paid_at: (Time.current if status == "succeeded")
    )
  end
end
