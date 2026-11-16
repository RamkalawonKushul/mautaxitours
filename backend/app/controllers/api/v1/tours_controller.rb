module Api
  module V1
    class ToursController < ApplicationController
      def index
        tours = Tour.published.order(:name)
        render json: tours.as_json(only: %i[id name slug summary description image_url duration_minutes price_cents currency])
      end

      def show
        tour = Tour.published.find_by!(slug: params[:id])
        render json: tour.as_json(only: %i[id name slug summary description image_url duration_minutes price_cents currency])
      end
    end
  end
end
