module Api
  module V1
    class BookingsController < ApplicationController
      def create
        booking = nil
        ActiveRecord::Base.transaction do
          items = params.require(:items)
          raise ActionController::BadRequest, "At least one tour is required" if items.blank?

          booking = Booking.create!(booking_params)
          total = 0
          items.each do |item|
            tour = Tour.published.find(item.require(:tour_id))
            quantity = Integer(item.require(:quantity))
            raise ActionController::BadRequest, "Quantity must be between 1 and 20" unless quantity.between?(1, 20)

            line_total = tour.price_cents * quantity
            booking.booking_items.create!(tour: tour, quantity: quantity, unit_price_cents: tour.price_cents, line_total_cents: line_total)
            total += line_total
          end
          booking.update!(total_cents: total)
        end

        render json: { reference: booking.reference, status: booking.status, payment_status: booking.payment_status, total_cents: booking.total_cents, currency: booking.currency }, status: :created
      rescue ActiveRecord::RecordInvalid => error
        render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity
      rescue ArgumentError, TypeError
        render json: { error: "Invalid quantity" }, status: :unprocessable_entity
      end

      def show
        booking = Booking.includes(booking_items: :tour).find_by!(reference: params[:id])
        render json: { reference: booking.reference, status: booking.status, payment_status: booking.payment_status, travel_date: booking.travel_date, total_cents: booking.total_cents, currency: booking.currency, items: booking.booking_items.map { |item| { tour: item.tour.name, quantity: item.quantity, line_total_cents: item.line_total_cents } } }
      end

      private

      def booking_params
        params.require(:booking).permit(:customer_name, :customer_email, :customer_phone, :travel_date, :pickup_details, :special_requests)
      end
    end
  end
end
