module Api
  module V1
    class BookingsController < ApplicationController
      def create
        booking = nil
        ActiveRecord::Base.transaction do
          items = params.require(:items)
          raise ActionController::BadRequest, "At least one tour is required" if items.blank?

          booking = Booking.new(booking_params)
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

            travel_date = item[:travel_date].presence || booking.travel_date
            raise ActionController::BadRequest, "A travel date is required for every tour" if travel_date.blank?

            vehicle = VehicleOption.active.find_by(name: item[:vehicle_name].to_s)
            vehicle ||= VehicleOption.active.first
            raise ActionController::BadRequest, "No active vehicle option is available" unless vehicle
            raise ActionController::BadRequest, "Vehicle and tour currencies must match" unless vehicle.currency == tour.currency

            transport_cents = tour.price_cents
            upgrade_cents = vehicle.upgrade_cents
            activity_priced = tour.adult_price_cents.present? && tour.child_price_cents.present?
            activity_cents = activity_priced ? (tour.adult_price_cents * adults) + (tour.child_price_cents * children) : 0
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
              vehicle_name: vehicle.name,
              transport_cents: transport_cents,
              vehicle_upgrade_cents: upgrade_cents,
              activity_cents: activity_cents,
              quoted_separately: !activity_priced
            )
            total += line_total
          end

          booking.currency = booking.booking_items.first.tour.currency
          raise ActionController::BadRequest, "All tours in one booking must use the same currency" unless booking.booking_items.all? { |item| item.tour.currency == booking.currency }
          booking.total_cents = total
          booking.save!
        end

        render json: serialize_booking(booking), status: :created
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
              line_total_cents: item.line_total_cents
            }
          end
        }
      end
    end
  end
end
