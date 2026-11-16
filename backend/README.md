# MauTaxi Tours API (Rails + PostgreSQL)

This is the backend foundation for the booking platform. The existing static customer website remains at the repository root while the Rails API is developed separately under `backend/`.

## Requirements

- Ruby 3.2+
- PostgreSQL 14+
- Bundler

## Local setup

```sh
cd backend
bundle install
cp .env.example .env
bin/rails db:create db:migrate
bin/rails server -p 3000
```

Set `DATABASE_URL` in your environment to a PostgreSQL connection string. Do not commit credentials or payment secrets.

## API

- `GET /api/v1/health` — service health
- `GET /api/v1/tours` — published tours
- `GET /api/v1/tours/:slug` — one published tour
- `POST /api/v1/bookings` — create a pending booking from published tour IDs and quantities
- `GET /api/v1/bookings/:reference` — retrieve booking summary

Prices are calculated from database tour prices; client-submitted prices are never trusted. New bookings start as pending/unpaid. Payment provider integration and authenticated admin operations are intentionally not enabled until the provider and production hosting are configured.

## Production checklist

1. Provision managed PostgreSQL and a Rails-compatible host.
2. Configure `DATABASE_URL`, `RAILS_MASTER_KEY`, `RAILS_ENV=production`, and `RAILS_LOG_TO_STDOUT=1` as secrets.
3. Run migrations and configure HTTPS, backups, monitoring, and mail delivery.
4. Add authenticated staff/admin access before exposing management operations.
5. Integrate a Mauritius-supported payment provider using signed server-side webhooks. Never mark a booking paid from a browser redirect alone.
6. Connect the existing website only after end-to-end staging tests.
