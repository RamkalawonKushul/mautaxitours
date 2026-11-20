module Api
  module V1
    class HealthController < ApplicationController
      def show
        ActiveRecord::Base.connection.select_value("SELECT 1")
        render json: { status: "ok", service: "MauTaxi Tours API", database: "ok", time: Time.current.iso8601 }
      rescue ActiveRecord::ActiveRecordError
        render json: { status: "unavailable", service: "MauTaxi Tours API" }, status: :service_unavailable
      end
    end
  end
end
