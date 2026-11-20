namespace :admin do
  desc "Create the first MauTaxi administrator (ADMIN_EMAIL and ADMIN_PASSWORD required)"
  task create: :environment do
    email = ENV.fetch("ADMIN_EMAIL").strip.downcase
    password = ENV.fetch("ADMIN_PASSWORD")
    abort "ADMIN_PASSWORD must contain at least 14 characters" if password.length < 14
    user = AdminUser.find_or_initialize_by(email: email)
    user.password = password
    user.save!
    puts "Administrator ready: #{user.email}"
  end
end
