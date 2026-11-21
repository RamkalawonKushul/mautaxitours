require "test_helper"

class Api::V1::Admin::DateFiltersControllerTest < ActionDispatch::IntegrationTest
  setup do
    admin = AdminUser.create!(
      email: "date-filter-admin@example.com",
      password: "a-secure-test-password-123"
    )
    token = Rails.application.message_verifier(:admin_session).generate(
      { admin_user_id: admin.id }, expires_in: 12.hours
    )
    @headers = { "Authorization" => "Bearer #{token}" }
  end

  test "bookings reject a reversed custom travel-date range" do
    process :get, "/api/v1/admin/bookings",
        params: { period: "custom", start_date: "2026-12-10", end_date: "2026-12-01" },
        headers: @headers,
        as: :json

    assert_response :unprocessable_entity, "Unexpected response: #{response.status} #{response.body}"
    assert_match(/valid date range/i, response.parsed_body.fetch("error"))
  end

  test "transfer enquiries require both custom travel-date endpoints" do
    process :get, "/api/v1/admin/transfers",
        params: { period: "custom", start_date: "2026-12-01" },
        headers: @headers,
        as: :json

    assert_response :unprocessable_entity, "Unexpected response: #{response.status} #{response.body}"
    assert_match(/valid date range/i, response.parsed_body.fetch("error"))
  end

  test "reports reject an invalid custom date" do
    process :get, "/api/v1/admin/reports",
        params: { period: "custom", start_date: "not-a-date", end_date: "2026-12-10" },
        headers: @headers,
        as: :json

    assert_response :unprocessable_entity, "Unexpected response: #{response.status} #{response.body}"
    assert_match(/valid date range/i, response.parsed_body.fetch("error"))
  end

  test "customer CRM rejects a reversed custom booking-date range" do
    process :get, "/api/v1/admin/customers",
        params: { period: "custom", start_date: "2026-12-10", end_date: "2026-12-01" },
        headers: @headers,
        as: :json

    assert_response :unprocessable_entity, "Unexpected response: #{response.status} #{response.body}"
    assert_match(/valid date range/i, response.parsed_body.fetch("error"))
  end
end
