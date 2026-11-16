module PaymentGateway
  class Adapter
    class NotConfigured < StandardError; end
    class UnsupportedOperation < StandardError; end

    def create_checkout_session(payment:)
      raise NotConfigured, "SBM merchant gateway credentials and integration contract have not been configured"
    end

    def verify_notification!(headers:, body:)
      raise NotConfigured, "SBM webhook verification is not configured"
    end

    def fetch_transaction(transaction_id:)
      raise NotConfigured, "SBM transaction lookup is not configured"
    end

    def refund(payment:, amount_cents: nil)
      raise NotConfigured, "SBM refund API details have not been configured"
    end
  end
end
