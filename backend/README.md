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
  "items": [{
    "tour_id": "cataileauxcerf-details",
    "travel_date": "2027-04-15",
    "adults": 2,
    "children": 1,
    "babies": 0,
    "vehicle_name": "Standard Car"
  }]
}
```

The API calculates each booking from published tour prices, activity rates and active vehicle options; browser-submitted prices are ignored. Passenger counts, vehicle capacity, currency, dates and customer email are validated on the server. New bookings start as pending/unpaid and receive a server-generated reference. Checkout retries can include an Idempotency-Key header to avoid duplicate bookings. Public reference lookup returns a limited summary and does not expose customer contact details. Customer and administrator email notifications are sent only when SMTP is configured; otherwise booking creation still succeeds and email delivery is skipped. The public website submits bookings to this API only after MAUTAXI_API_URL is configured.

## Deployment

The repository-root `render.yaml` Blueprint provisions the Rails API and PostgreSQL in Singapore. It uses the `backend/` directory as the Docker build root, runs database migrations as a pre-deploy step, and exposes `/api/v1/health` for health checks. Keep secrets in Render environment variables; never commit them to Git.

Before production: configure HTTPS, database backups, monitoring, SMTP delivery, staff credentials, login throttling, admin audit logs, and payment-provider webhooks. A booking must never be marked paid based only on a browser redirect. Use backend/.env.example as the environment-variable reference. Set SMTP_ADDRESS, SMTP_PORT, SMTP_DOMAIN, SMTP_USERNAME, SMTP_PASSWORD, MAILER_FROM and optionally ADMIN_NOTIFICATION_EMAIL to enable booking receipt, admin alert and booking-status emails. Verify the sender domain with your mail provider before sending customer mail.

## Payments (SBM-first)

SBM is the selected primary business bank and intended first acquiring provider. The payment foundation records payment attempts separately from bookings and includes a provider adapter contract and customer currency allowlist (MUR, EUR, USD, GBP).

The actual SBM checkout/API and webhook implementation is intentionally pending the bank's merchant integration pack. Do not enable live payments until SBM confirms merchant acquiring eligibility, supported transaction/settlement currencies, API documentation, sandbox credentials, webhook signing, fees and settlement arrangements. See [SBM gateway onboarding](docs/sbm-gateway-onboarding.md).

Foreign-currency amounts must be calculated server-side from a trusted, timestamped FX quote. Browser-provided prices or exchange rates are never authoritative. A payment is only successful after a verified server-to-server notification or authenticated transaction lookup; a customer redirect alone is not proof of payment.


## Administrator CMS setup

The live administrator editor is served at `/platform/admin/`. It requires the Rails API to be deployed separately over HTTPS and its URL entered on the sign-in screen. After the API is hosted, set `window.MAUTAXI_API_URL` in `platform/config.js` to the same API base URL and redeploy the static website; otherwise the public website continues using its bundled catalogue.

1. Provision PostgreSQL and deploy the `backend/` Rails application.
2. Set `DATABASE_URL`, `RAILS_MASTER_KEY` (if encrypted credentials are used), `SECRET_KEY_BASE`, `RAILS_ENV=production`, and `CORS_ORIGINS` to the exact HTTPS website origins (for example `https://mautaxitours.com,https://www.mautaxitours.com,https://mautaxitours.vercel.app`).
3. Deploy the API, run `bin/rails db:migrate db:seed` from `backend/`.
4. Create the first administrator securely on the host: `ADMIN_EMAIL=admin@example.com ADMIN_PASSWORD='use-a-long-unique-password' bin/rails admin:create`. Do not put the password in Git or a public chat.
5. Open `/platform/admin/`, enter the API base URL and the administrator credentials.

The initial seed imports the existing tour catalogue and the current vehicle capacities / upgrade surcharges. Seed runs do not overwrite tours that have already been created, so later administrator edits are retained.

### Administrator API

- `POST /api/v1/admin/session` — authenticate and receive a signed 12-hour bearer token.
- `GET/POST /api/v1/admin/tours`, `GET/PATCH/DELETE /api/v1/admin/tours/:id` — manage tours; delete archives rather than physically deleting booking history.
- `GET/POST /api/v1/admin/vehicles`, `PATCH/DELETE /api/v1/admin/vehicles/:id` — manage fleet and upgrade prices.
- `GET /api/v1/tours`, `GET /api/v1/tours/:slug`, `GET /api/v1/vehicles` — public read-only catalogue.

The admin booking, customer, transfer, payment-ledger and report endpoints are implemented and require the signed administrator bearer token. Payment records are read-only; there is no admin action that can mark a booking as paid. The static website still needs the deployed API URL, and all migrations must be run before live booking management can begin. Password reset, multi-admin roles, login throttling and audit history remain pre-production hardening tasks.


## Deploy on Render

1. Sign in at [Render](https://dashboard.render.com/) and connect the GitHub account that can access `RamkalawonKushul/mautaxitours`.
2. Choose **New + → Blueprint**, select the repository, and choose the `platform-modernization` branch.
3. Render reads the root `render.yaml`. Review the proposed `mautaxi-api` web service and `mautaxi-postgres` database, their Singapore region, and their paid plans before approving. Do not approve until you are comfortable with the monthly charges.
4. After provisioning, open the `mautaxi-api` service and check its deploy logs. The Blueprint runs `bin/rails db:migrate` before starting the API.
5. Confirm `https://YOUR-API.onrender.com/api/v1/health` returns JSON with `"status":"ok"`.
6. In the API service's Shell, run `bin/rails db:seed` once to load the initial tour and vehicle catalogue.
7. In the same Shell, create the first admin with environment variables entered securely in the Shell session (do not paste the password into Git or a public chat): `ADMIN_EMAIL=your-admin-email ADMIN_PASSWORD='your-unique-password-of-at-least-14-characters' bin/rails admin:create`.
8. Set `window.MAUTAXI_API_URL` in `platform/config.js` to the exact API base URL (for example `https://mautaxi-api.onrender.com`) and deploy the website frontend.
9. Test the admin login, create/edit a draft tour and vehicle, and verify the public tour list and cart before using the site with customers.

The Blueprint currently selects a 0.5 CPU / 512 MB web service and a 0.1 CPU / 256 MB PostgreSQL database with 5 GB storage, both in Singapore. Render's published compute prices make the starting estimate approximately US$14.20/month before taxes or any pricing changes: about US$7 for the web service, US$6 for the database compute, and about US$1.20 for the 4 GB storage above the included 1 GB. Check the current Render pricing and the exact Blueprint approval screen before creating resources.

The Blueprint is pinned to `platform-modernization`; it does not merge the pull request or alter `main`. The API deploys automatically after commits to that branch. The live website remains on its existing frontend host until its API URL is configured and the frontend is redeployed.
