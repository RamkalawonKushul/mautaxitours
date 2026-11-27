# Quote-request regression coverage includes missing vehicle prices and unpriced baby tickets.
require "test_helper"

class Api::V1::BookingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tour = Tour.create!(
      name: "Test lagoon trip",
      slug: "test-lagoon-trip",
      price_cents: 10_000,
      adult_price_cents: 2_000,
      child_price_cents: 1_000,
      currency: "MUR",
      published: true
    )
    @vehicle = VehicleOption.create!(
      name: "Test family car",
      capacity: 4,
      upgrade_cents: 500,
      currency: "MUR",
      active: true
    )
    @tour_vehicle_price = TourVehiclePrice.create!(
      tour: @tour,
      vehicle_option: @vehicle,
      price_cents: 10_500,
      currency: "MUR",
      active: true
    )
    @payload = {
      booking: {
        customer_name: "Test Guest",
        customer_email: "guest@example.com",
        customer_phone: "+23050000000",
        travel_date: (Date.current + 3.days).iso8601,
        pickup_details: "Test hotel"
      },
      items: [{
        tour_id: @tour.slug,
        travel_date: (Date.current + 3.days).iso8601,
        adults: 2,
        children: 1,
        babies: 0,
        vehicle_name: @vehicle.name
      }]
    }
  end

  test "creates a booking using server-side prices and returns a reference" do
    assert_difference("Booking.count", 1) do
      post api_v1_bookings_url,
           params: @payload,
           headers: { "Idempotency-Key" => "test-booking-key-0001" },
           as: :json
    end

    assert_response :created
    response_body = response.parsed_body
    assert_match(/\AMT-[A-Z0-9]{8}\z/, response_body.fetch("reference"))
    assert_equal 15_500, response_body.fetch("total_cents")
    assert_equal "pending", response_body.fetch("status")
    assert_equal "unpaid", response_body.fetch("payment_status")
  end

  test "uses the exact price configured for this tour and vehicle" do
    @tour_vehicle_price.update!(price_cents: 12_500)
    post api_v1_bookings_url, params: @payload, as: :json
    assert_response :created
    assert_equal 17_500, response.parsed_body.fetch("total_cents")
    assert_equal 12_500, response.parsed_body.fetch("items").first.fetch("transport_cents")
  end

  test "creates a quote-required booking when the selected vehicle has no tour price" do
    @tour_vehicle_price.destroy!

    assert_difference("Booking.count", 1) do
      post api_v1_bookings_url, params: @payload, as: :json
    end

    assert_response :created
    item = response.parsed_body.fetch("items").first
    assert_equal true, item.fetch("transport_quote_required")
    assert_equal 0, item.fetch("transport_cents")
    assert_equal 5_000, response.parsed_body.fetch("total_cents")
  end

  test "creates a quote-required booking when no vehicle is selected" do
    payload = @payload.deep_dup
    payload[:items].first.delete(:vehicle_name)

    assert_difference("Booking.count", 1) do
      post api_v1_bookings_url, params: payload, as: :json
    end

    assert_response :created
    item = response.parsed_body.fetch("items").first
    assert_equal true, item.fetch("transport_quote_required")
    assert_nil item.fetch("vehicle")
    assert_equal 0, item.fetch("transport_cents")
    assert_equal 5_000, response.parsed_body.fetch("total_cents")
  end

  test "marks an unpriced baby ticket as requiring a separate quote" do
    @tour.update!(baby_price_label: "Quoted separately")
    @payload[:items][0][:babies] = 1

    post api_v1_bookings_url, params: @payload, as: :json

    assert_response :created
    assert_equal true, response.parsed_body.fetch("items").first.fetch("quoted_separately")
  end

  test "retries with the same idempotency key do not create duplicate bookings" do
    post api_v1_bookings_url,
         params: @payload,
         headers: { "Idempotency-Key" => "test-booking-key-0002" },
         as: :json
    reference = response.parsed_body.fetch("reference")

    assert_no_difference("Booking.count") do
      post api_v1_bookings_url,
           params: @payload,
           headers: { "Idempotency-Key" => "test-booking-key-0002" },
           as: :json
    end

    assert_response :ok
    assert_equal reference, response.parsed_body.fetch("reference")
  end

  test "rejects reusing an idempotency key for a different booking request" do
    key = "test-booking-key-0003"
    post api_v1_bookings_url, params: @payload, headers: { "Idempotency-Key" => key }, as: :json
    assert_response :created

    changed_payload = @payload.deep_dup
    changed_payload[:booking][:customer_name] = "A different customer"
    assert_no_difference("Booking.count") do
      post api_v1_bookings_url, params: changed_payload, headers: { "Idempotency-Key" => key }, as: :json
    end

    assert_response :conflict
    assert_match(/different request/i, response.parsed_body.fetch("error"))
  end

  test "creates a quote-required booking when no single priced vehicle fits the group" do
    @payload[:items][0][:adults] = 5

    assert_difference("Booking.count", 1) do
      post api_v1_bookings_url, params: @payload, as: :json
    end

    assert_response :created
    item = response.parsed_body.fetch("items").first
    assert_equal true, item.fetch("transport_quote_required")
    assert_equal 0, item.fetch("transport_cents")
    assert_equal 11_000, response.parsed_body.fetch("total_cents")
  end

  test "public booking lookup does not expose customer contact details" do
    post api_v1_bookings_url, params: @payload, as: :json
    reference = response.parsed_body.fetch("reference")

    get api_v1_booking_url(reference), as: :json

    assert_response :success
    refute response.parsed_body.key?("customer_email")
    refute response.parsed_body.key?("customer_phone")
  end
end
