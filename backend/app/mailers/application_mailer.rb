class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch("MAILER_FROM", "bookings@mautaxitours.com") }
  layout false
end
