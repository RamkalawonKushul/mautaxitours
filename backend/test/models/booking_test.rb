require "test_helper"

class BookingTest < ActiveSupport::TestCase
  test "assigns a unique reference and defaults to pending and unpaid" do
    booking = Booking.new(
      customer_name: "Test Guest",
      customer_email: "guest@example.com",
      travel_date: Date.current + 1.day,
      total_cents: 0
    )
    assert booking.valid?
    assert_match(/\AMT-[A-Z0-9]{8}\z/, booking.reference)
    assert booking.pending?
    assert booking.unpaid?
  end
end
