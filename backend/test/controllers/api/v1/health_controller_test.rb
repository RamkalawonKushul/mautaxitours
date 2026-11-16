require "test_helper"

class Api::V1::HealthControllerTest < ActionDispatch::IntegrationTest
  test "returns a healthy API response" do
    get "/api/v1/health"
    assert_response :success
    assert_equal "ok", response.parsed_body["status"]
  end
end
