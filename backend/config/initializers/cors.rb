# Set CORS_ORIGINS as a comma-separated allowlist in each environment.
origins = ENV.fetch("CORS_ORIGINS", "http://localhost:8080,http://127.0.0.1:8080").split(",").map(&:strip).reject(&:empty?)
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*origins)
    resource "/api/*", headers: :any, methods: %i[get post options], expose: %w[Location]
  end
end
