module Api
  module V1
    class BookingsController < ApplicationController
      def create
        key = request.headers["Idempotency-Key"].presence
        if key.present? && !key.match?(/\A[a-zA-Z0-9_-]{16,128}\z/)
          raise ActionController::BadRequest, "Invalid booking request key"
        end

        if key.present? && (existing = Booking.includes(booking_items: :tour).find_by(idempotency_key: key))
          return render json: serialize_booking(existing), status: :ok
        end

        booking = nil
        ActiveRecord::Base.transaction do
          items = params.require(:items)
          raise ActionController::BadRequest, "At least one tour is required" if items.blank?

          booking = Booking.new(booking_params)
          booking.idempotency_key = key
          total = 0

          items.each do |item|
            identifier = item.require(:tour_id).to_s
            tour = Tour.published.find_by(slug: identifier)
            tour ||= Tour.published.find(identifier) if identifier.match?(/\A\d+\z/)
            raise ActiveRecord::RecordNotFound, "Tour not found" unless tour

            adults = integer_value(item[:adults], 1)
            children = integer_value(item[:children], 0)
            babies = integer_value(item[:babies], 0)
            travellers = adults + children + babies
            raise ActionController::BadRequest, "Each tour must have between 1 and 22 travellers" unless travellers.between?(1, 22)

            date_input = item[:travel_date].presence || booking.travel_date&.iso8601
            raise ActionController::BadRequest, "A travel date is required for every tour" if date_input.blank?
            begin
              travel_date = Date.iso8601(date_input.to_s)
            rescue Date::Error
              raise ActionController::BadRequest, "Each tour must have a valid travel date"
            end
            raise ActionController::BadRequest, "Travel dates cannot be in the past" if travel_date < Date.current

            vehicle_name = item[:vehicle_name].to_s.strip
            requested_vehicle = VehicleOption.active.find_by(name: vehicle_name) if vehicle_name.present?
            requested_vehicle_fits = requested_vehicle.present? && requested_vehicle.capacity >= travellers
            price = requested_vehicle_fits ? tour.tour_vehicle_prices.active.find_by(vehicle_option: requested_vehicle) : nil
            price = nil if price && price.currency != tour.currency

            # A missing or unsuitable single-vehicle price becomes a quote request.
            # Never add an unverified transport amount to the customer's booking total.
            transport_quote_required = price.nil?
            vehicle = price ? requested_vehicle : nil
            transport_cents = price&.price_cents || 0
            upgrade_cents = 0
            adult_activity_cents = (tour.adult_price_cents || 0) * adults
            child_activity_cents = (tour.child_price_cents || 0) * children
            activity_cents = adult_activity_cents + child_activity_cents
            baby_label = tour.baby_price_label.to_s.strip
            baby_quote_required = babies.positive? &&
                                  (baby_label.blank? || baby_label.match?(/quote|separately|on request|tbc/i))
            activity_quote_required = (adults.positive? && tour.adult_price_cents.nil?) ||
                                      (children.positive? && tour.child_price_cents.nil?) ||
                                      baby_quote_required
            line_total = transport_cents + upgrade_cents + activity_cents

            booking.booking_items.build(
              tour: tour,
              quantity: 1,
              unit_price_cents: line_total,
              line_total_cents: line_total,
              travel_date: travel_date,
              adults: adults,
              children: children,
              babies: babies,
              vehicle_option: vehicle,
              vehicle_name: vehicle&.name || vehicle_name.presence,
              transport_cents: transport_cents,
              vehicle_upgrade_cents: upgrade_cents,
              activity_cents: activity_cents,
              quoted_separately: activity_quote_required,
              transport_quote_required: transport_quote_required
            )
            total += line_total
          end

          booking.travel_date ||= booking.booking_items.first.travel_date
          booking.currency = booking.booking_items.first.tour.currency
          raise ActionController::BadRequest, "All tours in one booking must use the same currency" unless booking.booking_items.all? { |item| item.tour.currency == booking.currency }
          booking.total_cents = total
          booking.save!
        end

        send_booking_notifications(booking)
        render json: serialize_booking(booking), status: :created
      rescue ActiveRecord::RecordNotUnique
        existing = Booking.includes(booking_items: :tour).find_by!(idempotency_key: key)
        render json: serialize_booking(existing), status: :ok
      rescue ActiveRecord::RecordInvalid => error
        render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity
      rescue ArgumentError, TypeError
        render json: { error: "Passenger counts must be valid whole numbers" }, status: :unprocessable_entity
      end

      def show
        booking = Booking.includes(booking_items: :tour).find_by!(reference: params[:id])
        render json: serialize_booking(booking)
      end

      private

      def send_booking_notifications(booking)
        return unless BookingMailer.delivery_configured?

        BookingMailer.customer_confirmation(booking).deliver_now
        BookingMailer.admin_notification(booking).deliver_now if ENV["ADMIN_NOTIFICATION_EMAIL"].present?
      rescue StandardError => error
        Rails.logger.error("Booking notification failed for #{booking.reference}: #{error.class}: #{error.message}")
      end

      def integer_value(value, default)
        return default if value.nil?
        Integer(value)
      end

      def booking_params
        params.require(:booking).permit(:customer_name, :customer_email, :customer_phone, :travel_date, :pickup_details, :special_requests)
      end

      def serialize_booking(booking)
        {
          reference: booking.reference,
          status: booking.status,
          payment_status: booking.payment_status,
          travel_date: booking.travel_date,
          total_cents: booking.total_cents,
          currency: booking.currency,
          items: booking.booking_items.map do |item|
            {
              tour: item.tour.name,
              tour_slug: item.tour.slug,
              travel_date: item.travel_date,
              quantity: item.quantity,
              passengers: { adults: item.adults, children: item.children, babies: item.babies },
              vehicle: item.vehicle_name,
              transport_cents: item.transport_cents,
              vehicle_upgrade_cents: item.vehicle_upgrade_cents,
              activity_cents: item.activity_cents,
              quoted_separately: item.quoted_separately,
              transport_quote_required: item.transport_quote_required,
              line_total_cents: item.line_total_cents
            }
          end
        }
      end
    end
  end
end
