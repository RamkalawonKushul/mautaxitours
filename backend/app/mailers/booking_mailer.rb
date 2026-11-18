class BookingMailer < ApplicationMailer
  def self.delivery_configured?
    ENV["SMTP_ADDRESS"].present? && ENV["MAILER_FROM"].present?
  end

  def customer_confirmation(booking)
    @booking = booking
    mail(
      to: @booking.customer_email,
      from: ENV.fetch("MAILER_FROM"),
      subject: "MauTaxi Tours booking request received — #{@booking.reference}"
    ) do |format|
      format.text { render plain: customer_message }
    end
  end

  def admin_notification(booking)
    @booking = booking
    mail(
      to: ENV.fetch("ADMIN_NOTIFICATION_EMAIL"),
      from: ENV.fetch("MAILER_FROM"),
      reply_to: @booking.customer_email,
      subject: "New booking request — #{@booking.reference}"
    ) do |format|
      format.text { render plain: admin_message }
    end
  end

  def status_update(booking)
    @booking = booking
    mail(
      to: @booking.customer_email,
      from: ENV.fetch("MAILER_FROM"),
      subject: "MauTaxi Tours booking update — #{@booking.reference}"
    ) do |format|
      format.text { render plain: "Hello #{@booking.customer_name},\n\nYour booking request #{@booking.reference} is now marked as #{@booking.status.humanize}.\n\nThis status update does not indicate that a payment has been made. Payment status: #{@booking.payment_status.humanize}.\n\nOur team will contact you if further action is needed.\n\nMauTaxi Tours\n+230 58 22 44 12" }
    end
  end

  private

  def customer_message
    lines = [
      "Hello #{@booking.customer_name},",
      "",
      "Thank you for contacting MauTaxi Tours. We have received your booking request.",
      "Your reference is #{@booking.reference}.",
      "",
      "This is a request receipt, not a booking confirmation. Our team will check availability and contact you with the final details.",
      "",
      "Requested experiences:"
    ]
    @booking.booking_items.includes(:tour).each do |item|
      lines << "- #{item.tour.name} | #{item.travel_date} | #{item.adults} adults, #{item.children} children, #{item.babies} babies | #{item.vehicle_name}"
    end
    lines += [
      "",
      "Estimated amount currently recorded: #{@booking.currency} #{format('%.2f', @booking.total_cents / 100.0)}",
      "Some attraction tickets or optional extras may require a separate quote.",
      "",
      "No payment has been taken. Please wait for our team to confirm availability and provide the next steps.",
      "",
      "MauTaxi Tours",
      "+230 58 22 44 12",
      "mru@mautaxitours.com"
    ]
    lines.join("\n")
  end

  def admin_message
    lines = [
      "A new booking request has been saved.",
      "Reference: #{@booking.reference}",
      "Customer: #{@booking.customer_name}",
      "Email: #{@booking.customer_email}",
      "Phone: #{@booking.customer_phone}",
      "Travel date: #{@booking.travel_date}",
      "Pickup: #{@booking.pickup_details}",
      "Special requests: #{@booking.special_requests}",
      "Recorded total: #{@booking.currency} #{format('%.2f', @booking.total_cents / 100.0)}",
      "",
      "Experiences:"
    ]
    @booking.booking_items.includes(:tour).each do |item|
      lines << "- #{item.tour.name} | #{item.travel_date} | #{item.adults} adults, #{item.children} children, #{item.babies} babies | #{item.vehicle_name}"
    end
    lines.join("\n")
  end
end
