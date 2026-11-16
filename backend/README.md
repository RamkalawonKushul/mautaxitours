# MauTaxi Tours API (Rails + PostgreSQL)

The Rails API is being developed separately from the existing static customer website. This keeps the current production site untouched while the new platform is built and tested.

## Requirements

- Ruby 3.3.6 (or compatible Ruby 3.3)
- PostgreSQL 14+
- Bundler

## Local setup

```sh
cd backend
bundle install
export DATABASE_URL=postgresql://localhost/mautaxi_development
bin/rails db:prepare
bin/rails server -p 3000
```

## API

- `GET /api/v1/health` — service health
- `GET /api/v1/tours` — published tours
- `GET /api/v1/tours/:slug` — one published tour
- `POST /api/v1/bookings` — create a pending booking
- `GET /api/v1/bookings/:reference` — retrieve booking summary

Booking payload example:

```json
{
  "booking": {
    "customer_name": "Example Guest",
    "customer_email": "guest@example.com",
    "customer_phone": "+230 5xxxxxxx",
    "travel_date": "2027-04-15",
    "pickup_details": "Hotel name / pickup point",
    "special_requests": "Child seat required"
  },
  "items": [{ "tour_id": 1, "quantity": 2 }]
}
```

Prices are calculated from database tour prices; client-submitted prices are never trusted. New bookings start as pending/unpaid. Payment provider integration and authenticated admin operations are not enabled yet.

## Deployment

The included Dockerfile is a starting point for a Rails-compatible host. Provision PostgreSQL and set DATABASE_URL, RAILS_ENV=production, RAILS_LOG_TO_STDOUT=1, and a comma-separated CORS_ORIGINS allowlist. Keep secrets in the host's secret manager, never in Git.

Before production: configure HTTPS, database backups, monitoring, mail delivery, staff authentication/roles, admin audit logs, and payment-provider webhooks. A booking must never be marked paid based only on a browser redirect.
