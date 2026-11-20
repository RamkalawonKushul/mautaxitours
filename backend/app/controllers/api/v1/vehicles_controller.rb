module Api
  module V1
    class VehiclesController < ApplicationController
      def index
        render json: VehicleOption.active
      end
    end
  end
end
