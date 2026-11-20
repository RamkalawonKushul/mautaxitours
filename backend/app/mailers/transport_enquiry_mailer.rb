class TransportEnquiryMailer < ApplicationMailer
  def admin_notification(enquiry)
    @enquiry = enquiry
    mail(
      to: ENV.fetch("ADMIN_NOTIFICATION_EMAIL"),
      from: ENV.fetch("MAILER_FROM", "bookings@mautaxitours.com"),
      reply_to: @enquiry.contact_email.presence || ENV.fetch("MAILER_FROM", "bookings@mautaxitours.com"),
      subject: "New transfer enquiry — #{@enquiry.reference}"
    ) do |format|
      format.text do
        render plain: [
          "A new airport or private transport enquiry has been received.",
          "Reference: #{@enquiry.reference}",
          "Customer: #{@enquiry.contact_name}",
          "Email: #{@enquiry.contact_email}",
          "Phone: #{@enquiry.contact_phone}",
          "Route: #{@enquiry.pickup_location} → #{@enquiry.destination}",
          "Travel date: #{@enquiry.travel_date}",
          "Pickup time: #{@enquiry.pickup_time}",
          "Passengers: #{@enquiry.passengers}",
          "Vehicle preference: #{@enquiry.vehicle_preference}",
          "Flight number: #{@enquiry.flight_number}",
          "Luggage: #{@enquiry.luggage}",
          "Notes: #{@enquiry.notes}"
        ].join("\n")
      end
    end
  end
end
