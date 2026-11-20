module PaymentGateway
  class CurrencyPolicy
    SUPPORTED_CURRENCIES = %w[MUR EUR USD GBP].freeze

    def self.validate!(currency)
      normalized = currency.to_s.upcase
      raise ArgumentError, "Unsupported payment currency" unless SUPPORTED_CURRENCIES.include?(normalized)

      normalized
    end
  end
end
