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

  test "gateway adapter fails closed until MauBank credentials and contract are configured" do
    adapter = PaymentGateway::Adapter.new
    assert_raises(PaymentGateway::Adapter::NotConfigured) do
      adapter.create_checkout_session(payment: Object.new)
    end
  end
end
