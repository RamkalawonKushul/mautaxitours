module Api
  module V1
    module Admin
      class PaymentsController < BaseController
        def index
          payments = Payment.includes(:booking).order(created_at: :desc).limit(200)
          render json: payments.map do |payment|
            {
              id: payment.id,
              provider: payment.provider,
              status: payment.status,
              currency: payment.currency,
              amount_cents: payment.amount_cents,
              provider_payment_reference: payment.provider_payment_reference,
              provider_transaction_id: payment.provider_transaction_id,
              created_at: payment.created_at,
              paid_at: payment.paid_at,
              booking_reference: payment.booking.reference,
              booking_status: payment.booking.status
            }
          end
        end
      end
    end
  end
end
