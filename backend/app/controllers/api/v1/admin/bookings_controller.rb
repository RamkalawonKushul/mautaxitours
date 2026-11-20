module Api
  module V1
    module Admin
      class BookingsController < BaseController
        def index
          bookings = Booking.includes(booking_items: :tour).order(created_at: :desc)
          bookings = bookings.where(status: params[:status]) if Booking.statuses.key?(params[:status].to_s)
          bookings = apply_travel_date_filter(bookings)
          return if performed?

          if params[:q].present?
            term = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].to_s.strip)}%"
            bookings = bookings.where(
              "reference ILIKE :term OR customer_name ILIKE :term OR customer_email ILIKE :term OR customer_phone ILIKE :term",
              term: term
            )
          end
          render json: bookings.limit(200).map { |booking| serialize(booking) }
        end

        def show
          render json: serialize(Booking.includes(booking_items: :tour).find(params[:id]))
        end

        def update
          booking = Booking.find(params[:id])
          attributes = params.require(:booking).permit(:status)
          status = attributes[:status].to_s
          unless Booking.statuses.key?(status)
            return render json: { error: "Choose a valid booking status" }, status: :unprocessable_entity
          end
          if status == "cancelled" && booking.paid?
            return render json: { error: "This booking has a recorded payment. Verify the refund with the payment provider before cancelling it." }, status: :unprocessable_entity
          end

          previous_status = booking.status
          booking.update!(status: status)
          if previous_status != booking.status && BookingMailer.delivery_configured?
            begin
              BookingMailer.status_update(booking).deliver_now
            rescue StandardError => error
              Rails.logger.error("Booking status email failed for #{booking.reference}: #{error.class}: #{error.message}")
            end
          end
          render json: serialize(booking)
        rescue ActiveRecord::RecordInvalid => error
          render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity
        end

        private

        def apply_travel_date_filter(scope)
          range = requested_date_range
          return scope unless range
          start_date, end_date = range
          scope.left_joins(:booking_items)
               .where("bookings.travel_date BETWEEN :start_date AND :end_date OR booking_items.travel_date BETWEEN :start_date AND :end_date",
                      start_date: start_date, end_date: end_date)
               .distinct
        rescue ArgumentError
          render json: { error: "Choose a valid date range. The start date must be on or before the end date." }, status: :unprocessable_entity
          nil
        end

        def requested_date_range
          period = params[:period].to_s
          today = Date.current
          case period
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
        end

        def serialize(booking)
          {
            id: booking.id,
            reference: booking.reference,
            customer_name: booking.customer_name,
            customer_email: booking.customer_email,
            customer_phone: booking.customer_phone,
            travel_date: booking.travel_date,
            pickup_details: booking.pickup_details,
            special_requests: booking.special_requests,
            total_cents: booking.total_cents,
            currency: booking.currency,
            status: booking.status,
            payment_status: booking.payment_status,
            created_at: booking.created_at,
            items: booking.booking_items.map do |item|
              {
                tour: item.tour.name,
                tour_slug: item.tour.slug,
                travel_date: item.travel_date,
                adults: item.adults,
                children: item.children,
                babies: item.babies,
                vehicle: item.vehicle_name,
                transport_cents: item.transport_cents,
                vehicle_upgrade_cents: item.vehicle_upgrade_cents,
                activity_cents: item.activity_cents,
                quoted_separately: item.quoted_separately,
                line_total_cents: item.line_total_cents
              }
            end
          }
        end
      end
    end
  end
end
