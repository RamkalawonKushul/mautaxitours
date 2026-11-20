module Api
  module V1
    module Admin
      class SessionsController < ApplicationController
        def create
          user = AdminUser.find_by(email: params.dig(:admin, :email).to_s.downcase)
          unless user&.authenticate(params.dig(:admin, :password).to_s)
            return render json: { error: "Invalid email or password" }, status: :unauthorized
          end

          token = Rails.application.message_verifier(:admin_session).generate(
            { admin_user_id: user.id }, expires_in: 12.hours
          )
          render json: { token: token, expires_in: 12.hours.to_i, admin: { id: user.id, email: user.email } }
        end
      end
    end
  end
end
