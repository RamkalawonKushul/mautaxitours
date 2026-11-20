module Api
  module V1
    class ToursController < ApplicationController
      def index
        tours = Tour.published.order(:name)
        render json: tours.map { |tour| serialize(tour) }
      end

      def show
        render json: serialize(Tour.published.find_by!(slug: params[:id]))
      end

      private

      def serialize(tour)
        attributes = tour.as_json(only: %i[id name slug summary description image_url duration_minutes price_cents currency area category_key adult_price_cents child_price_cents baby_price_label included_items excluded_items itinerary gallery_image_urls])
        attributes["image_url"] = normalized_image_url(attributes["image_url"])
        attributes["vehicle_prices"] = tour.tour_vehicle_prices.active.map do |price|
          { vehicle_option_id: price.vehicle_option_id, vehicle_name: price.vehicle_option.name, capacity: price.vehicle_option.capacity, price_cents: price.price_cents, currency: price.currency }
        end
        attributes
      end

      def normalized_image_url(value)
        match = value.to_s.match(/\A\[([^\]]+)\]\((https?:\/\/[^)]+)\)\z/)
        match ? match[2] : value
      end
    end
  end
end
