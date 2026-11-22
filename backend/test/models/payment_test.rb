require "test_helper"

class PaymentTest < ActiveSupport::TestCase
  test "accepts supported customer currencies" do
    assert_equal "EUR", PaymentGateway::CurrencyPolicy.validate!("eur")
    assert_equal "USD", PaymentGateway::CurrencyPolicy.validate!("USD")
    assert_equal "GBP", PaymentGateway::CurrencyPolicy.validate!("gbp")
    assert_equal "MUR", PaymentGateway::CurrencyPolicy.validate!("mur")
  end

  test "rejects unsupported currencies" do
    assert_raises(ArgumentError) { PaymentGateway::CurrencyPolicy.validate!("AUD") }
  end

  test "only successful payments with a paid timestamp are verified" do
    booking = Booking.create!(customer_name: "Pending Guest", customer_email: "pending@example.com", travel_date: Date.current + 1.day, total_cents: 12_500, currency: "EUR")
    assert_empty Payment.verified, "A pending booking total without a verified payment must not be treated as collected revenue"
    base = { booking: booking, currency: "EUR", amount_cents: 12_500, base_amount_mur_cents: 600_000, fx_rate_to_mur: 48.0, fx_quoted_at: Time.current, idempotency_key: "payment-test-verified-0001" }
    initiated = Payment.create!(**base, status: "initiated", idempotency_key: "payment-test-initiated-0001")
    unverified = Payment.create!(**base, status: "succeeded", idempotency_key: "payment-test-no-paid-at-0001")
    verified = Payment.create!(**base, status: "succeeded", paid_at: Time.current, idempotency_key: "payment-test-paid-0001")

    assert_equal [verified.id], Payment.verified.pluck(:id)
    assert_not initiated.successful?
    assert_not unverified.successful?
    assert verified.successful?
  end

  test "payment currency must match its booking currency" do
    booking = Booking.create!(customer_name: "Euro Guest", customer_email: "euro@example.com", travel_date: Date.current + 1.day, total_cents: 12_500, currency: "EUR")
    payment = Payment.new(booking: booking, provider: "sbm", status: "initiated", currency: "MUR", amount_cents: 12_500, base_amount_mur_cents: 600_000, fx_rate_to_mur: 48.0, fx_quoted_at: Time.current, idempotency_key: "payment-currency-mismatch-0001")

    assert_not payment.valid?
    assert_includes payment.errors[:currency], "must match the booking currency"
  end

  test "gateway adapter fails closed until SBM merchant credentials and contract are configured" do
    adapter = PaymentGateway::Adapter.new
    assert_raises(PaymentGateway::Adapter::NotConfigured) do
      adapter.create_checkout_session(payment: Object.new)
    end
  end
end
