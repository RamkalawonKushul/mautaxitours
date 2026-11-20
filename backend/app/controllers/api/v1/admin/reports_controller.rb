module Api
  module V1
    module Admin
      class ReportsController < BaseController
        def show
          bookings = Booking.all
          verified_payments = Payment.where(status: "succeeded").where.not(paid_at: nil)

          revenue = verified_payments.group(:currency).sum(:amount_cents).map do |currency, total|
            { currency: currency, total_cents: total }
          end

          recent_bookings = bookings.order(created_at: :desc).limit(10).map do |booking|
            {
              reference: booking.reference,
              customer_name: booking.customer_name,
              status: booking.status,
              payment_status: booking.payment_status,
              total_cents: booking.total_cents,
              currency: booking.currency,
              created_at: booking.created_at
            }
          end

          render json: {
            bookings_total: bookings.count,
            bookings_pending: bookings.pending.count,
            bookings_confirmed: bookings.confirmed.count,
            bookings_cancelled: bookings.cancelled.count,
            paid_bookings_count: bookings.paid.count,
            payments_paid: verified_payments.count,
            unresolved_payments_count: Payment.where(status: %w[initiated awaiting_customer processing]).count,
            failed_payments_count: Payment.where(status: "failed").count,
            refunded_payments_count: Payment.where(status: "refunded").count,
            revenue_by_currency: revenue,
            recent_bookings: recent_bookings
          }
        end
      end
    end
  end
end
