module Api
  module V1
    module Admin
      class InitialSetupController < ApplicationController
        # This endpoint is only enabled while ADMIN_SETUP_TOKEN is configured and
        # no administrator exists. Remove the token immediately after first use.
        def create
          expected_token = ENV["ADMIN_SETUP_TOKEN"].to_s
          provided_token = request.headers["X-Admin-Setup-Token"].to_s

          return head :not_found if expected_token.blank? || AdminUser.exists?
          return render json: { error: "Setup authorization required" }, status: :unauthorized unless secure_token?(expected_token, provided_token)

          admin_params = params.require(:admin)
          email = admin_params.require(:email).to_s.strip.downcase
          password = admin_params.require(:password).to_s

          return render json: { error: "A valid email address is required" }, status: :unprocessable_entity unless email.match?(/\A[^@\s]+@[^@\s]+\.[^@\s]+\z/)
          return render json: { error: "Password must contain at least 14 characters" }, status: :unprocessable_entity if password.length < 14

          user = nil
          AdminUser.transaction do
            AdminUser.connection.execute("LOCK TABLE admin_users IN EXCLUSIVE MODE")
            raise ActiveRecord::RecordNotUnique if AdminUser.exists?

            user = AdminUser.create!(email: email, password: password)
          end
          render json: { created: true, admin: { id: user.id, email: user.email } }, status: :created
        rescue ActiveRecord::RecordNotUnique
          render json: { error: "Administrator setup has already been completed" }, status: :conflict
        rescue ActiveRecord::RecordInvalid => error
          render json: { error: error.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
        end

        private

        def secure_token?(expected, provided)
          expected.present? &&
            provided.present? &&
            ActiveSupport::SecurityUtils.secure_compare(expected, provided)
        end
      end
    end
  end
end
