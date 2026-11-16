require "test_helper"

class TransportEnquiryTest < ActiveSupport::TestCase
  test "assigns a reference and defaults to new" do
    enquiry = TransportEnquiry.create!(
      pickup_location: "SSR International Airport",
      destination: "Flic en Flac hotel",
      travel_date: Date.current + 7.days,
      pickup_time: "14:30",
      passengers: 3
    )

    assert_match(/\ATR-[A-Z0-9]{8}\z/, enquiry.reference)
    assert enquiry.new?
  end

  test "rejects passenger counts above fleet capacity" do
    enquiry = TransportEnquiry.new(
      pickup_location: "Airport",
      destination: "Hotel",
      travel_date: Date.current + 1.day,
      pickup_time: "10:00",
      passengers: 23
    )

    assert_not enquiry.valid?
    assert_includes enquiry.errors.attribute_names, :passengers
  end
end
