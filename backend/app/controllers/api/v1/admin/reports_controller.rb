module Api
  module V1
    module Admin
      class ReportsController < BaseController
        def show
          bookings = apply_date_filter(Booking.all, :created_at)
          verified_payments = apply_date_filter(Payment.where(status: "succeeded").where.not(paid_at: nil), :paid_at)

          revenue = verified_payments.group(:currency).sum(:amount_cents).map do |currency, total|
            { currency: currency, total_cents: total }
          end

          render json: {
            bookings_total: bookings.count,
            bookings_pending: bookings.pending.count,
            bookings_confirmed: bookings.confirmed.count,
            bookings_cancelled: bookings.cancelled.count,
            paid_bookings_count: bookings.paid.count,
            payments_paid: verified_payments.count,
            unresolved_payments_count: apply_date_filter(Payment.where(status: %w[initiated awaiting_customer processing]), :created_at).count,
            failed_payments_count: apply_date_filter(Payment.where(status: "failed"), :created_at).count,
            refunded_payments_count: apply_date_filter(Payment.where(status: "refunded"), :created_at).count,
            revenue_by_currency: revenue,
            recent_bookings: bookings.order(created_at: :desc).limit(10).map do |booking|
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
          }
        end

        private

        def apply_date_filter(scope, field)
          start_date = parse_date(params[:start_date])
          end_date = parse_date(params[:end_date])
          if params[:period] == "day"
            start_date ||= Date.current
            end_date ||= start_date
          elsif params[:period] == "month"
            start_date ||= Date.current.beginning_of_month
            end_date ||= Date.current.end_of_month
          elsif params[:period] == "year"
            start_date ||= Date.current.beginning_of_year
            end_date ||= Date.current.end_of_year
          end
          scope = scope.where(field => start_date.beginning_of_day..) if start_date
          scope = scope.where(field => ..end_date.end_of_day) if end_date
          scope
        end

        def parse_date(value)
          Date.iso8601(value) if value.present?
        rescue Date::Error
          nil
        end
      end
    end
  end
end
