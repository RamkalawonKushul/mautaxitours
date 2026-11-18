module Api
  module V1
    module Admin
      class ReportsController < BaseController
        def show
          bookings = Booking.all
          revenue = bookings.where(payment_status: :paid).group(:currency).sum(:total_cents).map do |currency, total|
            { currency: currency, total_cents: total }
          end
          render json: {
            bookings_total: bookings.count,
            bookings_pending: bookings.pending.count,
            bookings_confirmed: bookings.confirmed.count,
            bookings_cancelled: bookings.cancelled.count,
            payments_paid: bookings.paid.count,
            revenue_by_currency: revenue,
            recent_bookings: Booking.order(created_at: :desc).limit(10).map do |booking|
              { reference: booking.reference, customer_name: booking.customer_name, status: booking.status, payment_status: booking.payment_status, total_cents: booking.total_cents, currency: booking.currency, created_at: booking.created_at }
            end
          }
        end
      end
    end
  end
end
