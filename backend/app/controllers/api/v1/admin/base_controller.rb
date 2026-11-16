module Api
  module V1
    module Admin
      class BaseController < ApplicationController
        before_action :authenticate_admin!

        private

        def authenticate_admin!
          token = request.headers["Authorization"].to_s.delete_prefix("Bearer ").presence
          raise ActiveSupport::MessageVerifier::InvalidSignature unless token
          payload = Rails.application.message_verifier(:admin_session).verified(token)
          @current_admin = AdminUser.find(payload.fetch("admin_user_id"))
        rescue ActiveSupport::MessageVerifier::InvalidSignature, KeyError, ActiveRecord::RecordNotFound
          render json: { error: "Administrator authentication required" }, status: :unauthorized
        end
      end
    end
  end
end
