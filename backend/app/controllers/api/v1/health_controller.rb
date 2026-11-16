module Api
  module V1
    class HealthController < ApplicationController
      def show
        render json: { status: "ok", service: "MauTaxi Tours API", time: Time.current.iso8601 }
      end
    end
  end
end
