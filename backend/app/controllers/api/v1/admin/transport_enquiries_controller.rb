module Api
  module V1
    module Admin
      class TransportEnquiriesController < BaseController
        def index
          enquiries = TransportEnquiry.order(created_at: :desc)
          enquiries = enquiries.where(status: params[:status]) if TransportEnquiry.statuses.key?(params[:status].to_s)
          if params[:q].present?
            term = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].to_s.strip)}%"
            enquiries = enquiries.where(
              "reference ILIKE :term OR pickup_location ILIKE :term OR destination ILIKE :term OR contact_name ILIKE :term OR contact_phone ILIKE :term",
              term: term
            )
          end
          render json: enquiries.limit(200)
        end

        def update
          enquiry = TransportEnquiry.find(params[:id])
          status = params.require(:transport_enquiry).permit(:status)[:status].to_s
          unless TransportEnquiry.statuses.key?(status)
            return render json: { error: "Choose a valid transfer enquiry status" }, status: :unprocessable_entity
          end
          enquiry.update!(status: status)
          render json: enquiry
        rescue ActiveRecord::RecordInvalid => error
          render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end
end
