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
        tour.as_json(only: %i[id name slug summary description image_url duration_minutes price_cents currency area category_key adult_price_cents child_price_cents baby_price_label included_items excluded_items itinerary gallery_image_urls])
      end
    end
  end
end
