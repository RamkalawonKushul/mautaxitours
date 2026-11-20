require "test_helper"

class Api::V1::ToursControllerTest < ActionDispatch::IntegrationTest
  test "public tour catalogue includes exact active prices for each vehicle option" do
    tour = Tour.create!(name: "Public test tour", slug: "public-test-tour", price_cents: 0, currency: "MUR", published: true)
    vehicle = VehicleOption.create!(name: "Public test car", capacity: 4, upgrade_cents: 0, currency: "MUR", active: true)
    TourVehiclePrice.create!(tour: tour, vehicle_option: vehicle, price_cents: 245_000, currency: "MUR", active: true)

    get api_v1_tours_url, as: :json

    assert_response :success
    result = response.parsed_body.find { |record| record.fetch("slug") == tour.slug }
    assert_equal 1, result.fetch("vehicle_prices").length
    price = result.fetch("vehicle_prices").first
    assert_equal "Public test car", price.fetch("vehicle_name")
    assert_equal 245_000, price.fetch("price_cents")
    assert_equal "MUR", price.fetch("currency")
  end

  test "public tour catalogue does not publish inactive vehicle prices" do
    tour = Tour.create!(name: "Hidden price tour", slug: "hidden-price-tour", price_cents: 0, currency: "MUR", published: true)
    vehicle = VehicleOption.create!(name: "Hidden price car", capacity: 4, upgrade_cents: 0, currency: "MUR", active: true)
    TourVehiclePrice.create!(tour: tour, vehicle_option: vehicle, price_cents: 100_000, currency: "MUR", active: false)

    get api_v1_tours_url, as: :json

    result = response.parsed_body.find { |record| record.fetch("slug") == tour.slug }
    assert_empty result.fetch("vehicle_prices")
  end
end
