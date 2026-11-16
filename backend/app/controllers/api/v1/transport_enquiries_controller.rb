module Api
  module V1
    class TransportEnquiriesController < ApplicationController
      def create
        enquiry = TransportEnquiry.create!(enquiry_params)
        render json: {
          reference: enquiry.reference,
          status: enquiry.status,
          message: "Your transfer enquiry has been received. MauTaxi Tours will contact you to confirm availability and price."
        }, status: :created
      rescue ActiveRecord::RecordInvalid => error
        render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity
      end

      private

      def enquiry_params
        params.require(:transport_enquiry).permit(
          :pickup_location, :destination, :travel_date, :pickup_time,
          :passengers, :vehicle_preference, :flight_number, :luggage,
          :notes, :contact_name, :contact_phone, :contact_email
        )
      end
    end
  end
end
