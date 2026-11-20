require "test_helper"

class Api::V1::Admin::InitialSetupControllerTest < ActionDispatch::IntegrationTest
  setup do
    @previous_setup_token = ENV["ADMIN_SETUP_TOKEN"]
    ENV["ADMIN_SETUP_TOKEN"] = "test-only-admin-setup-token-with-sufficient-entropy"
  end

  teardown do
    if @previous_setup_token.nil?
      ENV.delete("ADMIN_SETUP_TOKEN")
    else
      ENV["ADMIN_SETUP_TOKEN"] = @previous_setup_token
    end
  end

  test "creates the first administrator with the setup token" do
    assert_difference("AdminUser.count", 1) do
      post "/api/v1/admin/initial_setup",
           params: { admin: { email: "OWNER@example.com", password: "a-secure-test-password-123" } },
           headers: { "X-Admin-Setup-Token" => ENV.fetch("ADMIN_SETUP_TOKEN") },
           as: :json
    end

    assert_response :created
    assert_equal "owner@example.com", response.parsed_body.dig("admin", "email")
  end

  test "rejects an incorrect setup token" do
    assert_no_difference("AdminUser.count") do
      post "/api/v1/admin/initial_setup",
           params: { admin: { email: "owner@example.com", password: "a-secure-test-password-123" } },
           headers: { "X-Admin-Setup-Token" => "wrong-token" },
           as: :json
    end

    assert_response :unauthorized
  end

  test "does not allow setup after an administrator exists" do
    AdminUser.create!(email: "existing@example.com", password: "a-secure-test-password-123")

    assert_no_difference("AdminUser.count") do
      post "/api/v1/admin/initial_setup",
           params: { admin: { email: "another@example.com", password: "a-secure-test-password-123" } },
           headers: { "X-Admin-Setup-Token" => ENV.fetch("ADMIN_SETUP_TOKEN") },
           as: :json
    end

    assert_response :not_found
  end
end
