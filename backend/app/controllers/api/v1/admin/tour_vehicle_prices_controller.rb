module Api
  module V1
    module Admin
      class TourVehiclePricesController < BaseController
        before_action :set_tour
        before_action :set_price, only: %i[update destroy]

        def index
          render json: @tour.tour_vehicle_prices.includes(:vehicle_option).order("vehicle_options.capacity ASC").map { |price| serialize(price) }
        end

        def create
          price = @tour.tour_vehicle_prices.new(price_params)
          if price.save
            render json: serialize(price), status: :created
          else
            render json: { errors: price.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          if @price.update(price_params)
            render json: serialize(@price)
          else
            render json: { errors: @price.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          @price.update!(active: false)
          head :no_content
        end

        private

        def set_tour
          @tour = Tour.find(params[:tour_id])
        end

        def set_price
          @price = @tour.tour_vehicle_prices.find(params[:id])
        end

        def price_params
          params.require(:tour_vehicle_price).permit(:vehicle_option_id, :price_cents, :currency, :active)
        end

        def serialize(price)
          price.as_json(only: %i[id tour_id vehicle_option_id price_cents currency active]).merge(
            vehicle_name: price.vehicle_option.name,
            capacity: price.vehicle_option.capacity
          )
        end
      end
    end
  end
end
