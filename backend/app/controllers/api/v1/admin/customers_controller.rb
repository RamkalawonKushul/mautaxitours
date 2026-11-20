module Api
  module V1
    module Admin
      class CustomersController < BaseController
        def index
          bookings = Booking.includes(:booking_items).order(created_at: :desc)
          bookings = apply_date_filter(bookings)
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

        def apply_date_filter(scope)
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
          scope = scope.where(created_at: start_date.beginning_of_day..) if start_date
          scope = scope.where(created_at: ..end_date.end_of_day) if end_date
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
