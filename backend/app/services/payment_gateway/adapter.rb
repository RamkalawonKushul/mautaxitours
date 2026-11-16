module PaymentGateway
  class Adapter
    class NotConfigured < StandardError; end
    class UnsupportedOperation < StandardError; end

    def create_checkout_session(payment:)
      raise NotConfigured, "MauBank merchant API details have not been configured"
    end

    def verify_notification!(headers:, body:)
      raise NotConfigured, "MauBank webhook verification is not configured"
    end

    def fetch_transaction(transaction_id:)
      raise NotConfigured, "MauBank transaction lookup is not configured"
    end

    def refund(payment:, amount_cents: nil)
      raise NotConfigured, "MauBank refund API details have not been configured"
    end
  end
end
