module Api
  module V1
    module Admin
      class CustomersController < BaseController
        def index
          bookings = Booking.includes(:booking_items).order(created_at: :desc).limit(1000)
          grouped = bookings.group_by { |booking| booking.customer_email.to_s.downcase }
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
      end
    end
  end
end
