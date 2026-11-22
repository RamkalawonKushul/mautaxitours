require "test_helper"

class Api::V1::Admin::OperatorManagementControllerTest < ActionDispatch::IntegrationTest
  setup do
    admin = AdminUser.create!(
      email: "operator-admin@example.com",
      password: "a-secure-test-password-123"
    )
    token = Rails.application.message_verifier(:admin_session).generate(
      { admin_user_id: admin.id }, expires_in: 12.hours
    )
    @headers = { "Authorization" => "Bearer #{token}" }
    @booking = Booking.create!(
      customer_name: "Test Customer",
      customer_email: "customer@example.com",
      travel_date: Date.current + 10.days,
      total_cents: 50_000,
      currency: "EUR"
    )
    @operator = Operator.create!(name: "Island Transport", email: "ops@example.com")
  end

  test "administrator can create an operator assignment and records the expected margin" do
    post "/api/v1/admin/operator_assignments",
         params: { operator_assignment: {
           booking_id: @booking.id,
           operator_id: @operator.id,
           operator_cost_cents: 30_000,
           currency: "EUR"
         } },
         headers: @headers,
         as: :json

    assert_response :created
    assert_equal 20_000, response.parsed_body.fetch("estimated_margin_cents")
  end


  test "administrator can assign a transfer enquiry and records the expected margin" do
    enquiry = TransportEnquiry.create!(
      pickup_location: "Airport",
      destination: "Grand Baie",
      travel_date: Date.current + 10.days,
      pickup_time: "10:00",
      passengers: 3,
      contact_name: "Transfer Customer",
      contact_email: "transfer@example.com"
    )

    post "/api/v1/admin/operator_assignments",
         params: { operator_assignment: {
           transport_enquiry_id: enquiry.id,
           operator_id: @operator.id,
           operator_cost_cents: 20_000,
           customer_price_cents: 35_000,
           currency: "MUR"
         } },
         headers: @headers,
         as: :json

    assert_response :created
    assert_equal 15_000, response.parsed_body.fetch("estimated_margin_cents")
  end

  test "operator assignment rejects a cost in a different currency" do
    post "/api/v1/admin/operator_assignments",
         params: { operator_assignment: {
           booking_id: @booking.id,
           operator_id: @operator.id,
           operator_cost_cents: 30_000,
           currency: "MUR"
         } },
         headers: @headers,
         as: :json

    assert_response :unprocessable_entity
  end


  test "a new operator assignment marks the previous booking assignment as reassigned" do
    first = @booking.operator_assignments.create!(
      operator: @operator,
      operator_cost_cents: 20_000,
      currency: "EUR"
    )
    second_operator = Operator.create!(name: "Backup Transport")

    post "/api/v1/admin/operator_assignments",
         params: { operator_assignment: {
           booking_id: @booking.id,
           operator_id: second_operator.id,
           operator_cost_cents: 25_000,
           currency: "EUR"
         } },
         headers: @headers,
         as: :json

    assert_response :created
    assert_equal "reassigned", first.reload.status
  end

  test "transfer operator assignments reject unsupported currencies" do
    enquiry = TransportEnquiry.create!(
      pickup_location: "Airport",
      destination: "Grand Baie",
      travel_date: Date.current + 10.days,
      pickup_time: "10:00",
      passengers: 2,
      contact_name: "Currency Test",
      contact_email: "currency@example.com"
    )

    post "/api/v1/admin/operator_assignments",
         params: { operator_assignment: {
           transport_enquiry_id: enquiry.id,
           operator_id: @operator.id,
           operator_cost_cents: 20_000,
           customer_price_cents: 35_000,
           currency: "AUD"
         } },
         headers: @headers,
         as: :json

    assert_response :unprocessable_entity
    assert_match(/currency/i, response.parsed_body.fetch("errors").join(" "))
  end

  test "operator paid amount cannot exceed the agreed cost" do
    assignment = @booking.operator_assignments.create!(
      operator: @operator,
      operator_cost_cents: 20_000,
      currency: "EUR"
    )

    patch "/api/v1/admin/operator_assignments/#{assignment.id}",
          params: { operator_assignment: { operator_paid_cents: 20_001 } },
          headers: @headers,
          as: :json

    assert_response :unprocessable_entity
    assert_equal 0, assignment.reload.operator_paid_cents
  end

  test "operator cannot be deleted while assignments exist" do
    @booking.operator_assignments.create!(
      operator: @operator,
      operator_cost_cents: 30_000,
      currency: "EUR"
    )

    delete "/api/v1/admin/operators/#{@operator.id}", headers: @headers

    assert_response :no_content
    assert_not @operator.reload.active?
  end
end
