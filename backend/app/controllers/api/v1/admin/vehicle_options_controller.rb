module Api
  module V1
    module Admin
      class VehicleOptionsController < BaseController
        def index
          render json: VehicleOption.order(:capacity, :upgrade_cents)
        end

        def create
          vehicle = VehicleOption.new(vehicle_params)
          if vehicle.save
            render json: vehicle, status: :created
          else
            render json: { errors: vehicle.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          vehicle = VehicleOption.find(params[:id])
          if vehicle.update(vehicle_params)
            render json: vehicle
          else
            render json: { errors: vehicle.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          VehicleOption.find(params[:id]).update!(active: false)
          head :no_content
        end

        private

        def vehicle_params
          params.require(:vehicle_option).permit(:name, :capacity, :upgrade_cents, :currency, :active)
        end
      end
    end
  end
end
