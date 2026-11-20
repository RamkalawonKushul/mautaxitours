module Api
  module V1
    module Admin
      class CustomersController < BaseController
        def index
          range = requested_date_range
          return if performed?

          bookings = Booking.includes(:booking_items).order(created_at: :desc)
          bookings = apply_date_filter(bookings, range)
          grouped = bookings.limit(1000).group_by { |booking| booking.customer_email.to_s.downcase }
          rows = grouped.map do |email, records|
            latest = records.first
            {
              customer_name: latest.customer_name,
              customer_email: email,
              customer_phone: latest.customer_phone,
              bookings_count: records.length,
              last_booking_at: latest.created_at,
              references: records.first(10).map(&:reference),
              totals_by_currency: records.group_by(&:currency).map do |currency, entries|
                { currency: currency, total_cents: entries.sum(&:total_cents) }
              end
            }
          end
          if params[:q].present?
            term = params[:q].to_s.downcase
            rows.select! { |row| [row[:customer_name], row[:customer_email], row[:customer_phone]].compact.any? { |value| value.downcase.include?(term) } }
          end
          render json: rows.sort_by { |row| row[:last_booking_at] || Time.at(0) }.reverse
        end

        private

        def apply_date_filter(scope, range)
          return scope unless range
          start_date, end_date = range
          scope.where(created_at: start_date.beginning_of_day..end_date.end_of_day)
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
