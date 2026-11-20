module Api
  module V1
    module Admin
      class TransportEnquiriesController < BaseController
        def index
          enquiries = TransportEnquiry.order(created_at: :desc)
          enquiries = enquiries.where(status: params[:status]) if TransportEnquiry.statuses.key?(params[:status].to_s)
          enquiries = apply_travel_date_filter(enquiries)
          return if performed?

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

        private

        def apply_travel_date_filter(scope)
          range = requested_date_range
          return scope unless range
          start_date, end_date = range
          scope.where(travel_date: start_date..end_date)
        rescue ArgumentError
          render json: { error: "Choose a valid date range. The start date must be on or before the end date." }, status: :unprocessable_entity
          nil
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
        end
      end
    end
  end
end
