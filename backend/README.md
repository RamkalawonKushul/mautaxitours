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
- `POST /api/v1/transport_enquiries` — create an airport/private transport enquiry (no fare is quoted automatically)

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

## Payments (SBM-first)

SBM is the selected primary business bank and intended first acquiring provider. The payment foundation records payment attempts separately from bookings and includes a provider adapter contract and customer currency allowlist (MUR, EUR, USD, GBP).

The actual SBM checkout/API and webhook implementation is intentionally pending the bank's merchant integration pack. Do not enable live payments until SBM confirms merchant acquiring eligibility, supported transaction/settlement currencies, API documentation, sandbox credentials, webhook signing, fees and settlement arrangements. See [SBM gateway onboarding](docs/sbm-gateway-onboarding.md).

Foreign-currency amounts must be calculated server-side from a trusted, timestamped FX quote. Browser-provided prices or exchange rates are never authoritative. A payment is only successful after a verified server-to-server notification or authenticated transaction lookup; a customer redirect alone is not proof of payment.


## Administrator CMS setup

The live administrator editor is served at `/platform/admin/`. It requires the Rails API to be deployed separately over HTTPS and its URL entered on the sign-in screen. After the API is hosted, set `window.MAUTAXI_API_URL` in `platform/config.js` to the same API base URL and redeploy the static website; otherwise the public website continues using its bundled catalogue.

1. Provision PostgreSQL and deploy the `backend/` Rails application.
2. Set `DATABASE_URL`, `RAILS_MASTER_KEY` (if encrypted credentials are used), `SECRET_KEY_BASE`, `RAILS_ENV=production`, and `CORS_ORIGINS` to the exact HTTPS website origins (for example `https://mautaxitours.com,https://www.mautaxitours.com`).
3. Deploy the API, run `bin/rails db:migrate db:seed` from `backend/`.
4. Create the first administrator securely on the host: `ADMIN_EMAIL=admin@example.com ADMIN_PASSWORD='use-a-long-unique-password' bin/rails admin:create`. Do not put the password in Git or a public chat.
5. Open `/platform/admin/`, enter the API base URL and the administrator credentials.

The initial seed imports the existing tour catalogue and the current vehicle capacities / upgrade surcharges. Seed runs do not overwrite tours that have already been created, so later administrator edits are retained.

### Administrator API

- `POST /api/v1/admin/session` — authenticate and receive a signed 12-hour bearer token.
- `GET/POST /api/v1/admin/tours`, `GET/PATCH/DELETE /api/v1/admin/tours/:id` — manage tours; delete archives rather than physically deleting booking history.
- `GET/POST /api/v1/admin/vehicles`, `PATCH/DELETE /api/v1/admin/vehicles/:id` — manage fleet and upgrade prices.
- `GET /api/v1/tours`, `GET /api/v1/tours/:slug`, `GET /api/v1/vehicles` — public read-only catalogue.

Tour images are currently managed by editing their HTTPS image URL. A managed image upload/storage workflow, password reset, multi-admin roles, login throttling, audit history, and full booking/payment management are not yet included. Add those controls before opening the CMS to multiple staff members. The API and database must be hosted and configured before live edits are available; the static Vercel deployment alone does not provide a Rails database.
