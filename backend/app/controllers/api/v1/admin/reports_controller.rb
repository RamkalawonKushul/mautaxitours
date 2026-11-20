module Api
  module V1
    module Admin
      class ReportsController < BaseController
        def show
          range = requested_date_range
          return if performed?

          bookings = apply_date_filter(Booking.all, :created_at, range)
          verified_payments = apply_date_filter(Payment.where(status: "succeeded").where.not(paid_at: nil), :paid_at, range)

          revenue = verified_payments.group(:currency).sum(:amount_cents).map do |currency, total|
            { currency: currency, total_cents: total }
          end

          finance_bookings = bookings.where.not(status: "cancelled")
          booking_value = finance_bookings.group(:currency).sum(:total_cents)
          transfer_enquiries = apply_date_filter(TransportEnquiry.all, :created_at, range)
          active_booking_assignments = OperatorAssignment.joins(:booking)
                                                           .where(booking_id: finance_bookings.select(:id))
                                                           .where.not(status: %w[declined cancelled reassigned])
          active_transfer_assignments = OperatorAssignment.joins(:transport_enquiry)
                                                            .where(transport_enquiry_id: transfer_enquiries.where.not(status: "cancelled").select(:id))
                                                            .where.not(status: %w[declined cancelled reassigned])
          transfer_value = active_transfer_assignments.group(:currency).sum(:customer_price_cents)
          booking_value = booking_value.merge(transfer_value) { |_currency, booking_total, transfer_total| booking_total + transfer_total }
          booking_costs = active_booking_assignments.group(:currency).sum(:operator_cost_cents)
          transfer_costs = active_transfer_assignments.group(:currency).sum(:operator_cost_cents)
          operator_costs = booking_costs.merge(transfer_costs) { |_currency, booking_cost, transfer_cost| booking_cost + transfer_cost }
          booking_outstanding = active_booking_assignments.group(:currency).sum("operator_cost_cents - operator_paid_cents")
          transfer_outstanding = active_transfer_assignments.group(:currency).sum("operator_cost_cents - operator_paid_cents")
          operator_outstanding = booking_outstanding.merge(transfer_outstanding) { |_currency, booking_due, transfer_due| booking_due + transfer_due }
          finance_currencies = (booking_value.keys + operator_costs.keys).uniq.sort
          estimated_margin = finance_currencies.map do |currency|
            { currency: currency, total_cents: booking_value.fetch(currency, 0) - operator_costs.fetch(currency, 0) }
          end

          render json: {
            bookings_total: bookings.count,
            bookings_pending: bookings.pending.count,
            bookings_confirmed: bookings.confirmed.count,
            bookings_cancelled: bookings.cancelled.count,
            paid_bookings_count: bookings.paid.count,
            payments_paid: verified_payments.count,
            unresolved_payments_count: apply_date_filter(Payment.where(status: %w[initiated awaiting_customer processing]), :created_at, range).count,
            failed_payments_count: apply_date_filter(Payment.where(status: "failed"), :created_at, range).count,
            refunded_payments_count: apply_date_filter(Payment.where(status: "refunded"), :created_at, range).count,
            revenue_by_currency: revenue,
            booking_value_by_currency: booking_value.map { |currency, total| { currency: currency, total_cents: total } },
            operator_costs_by_currency: operator_costs.map { |currency, total| { currency: currency, total_cents: total } },
            operator_outstanding_by_currency: operator_outstanding.map { |currency, total| { currency: currency, total_cents: total } },
            estimated_margin_by_currency: estimated_margin,
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

        def apply_date_filter(scope, field, range)
          return scope unless range
          start_date, end_date = range
          scope.where(field => start_date.beginning_of_day..end_date.end_of_day)
        end

        def requested_date_range
          today = Date.current
          case params[:period].to_s
          when "day" then [today, today]
          when "month" then [today.beginning_of_month, today.end_of_month]
          when "year" then [today.beginning_of_year, today.end_of_year]
          when "custom"
            raise ArgumentError unless params[:start_date].present? && params[:end_date].present?
            start_date = Date.iso8601(params[:start_date])
            end_date = Date.iso8601(params[:end_date])
            raise ArgumentError if start_date > end_date
            [start_date, end_date]
          else
            nil
          end
        rescue ArgumentError
          render json: { error: "Choose a valid date range. The start date must be on or before the end date." }, status: :unprocessable_entity
          nil
        end
      end
    end
  end
end
