# SBM e-commerce gateway integration — MauTaxi Tours

## Selected acquiring bank

SBM Bank (Mauritius) Ltd is the selected acquiring bank for MauTaxi Tours. SBM publicly describes an e-commerce acquiring service with online transaction processing, merchant transaction monitoring, voids and refunds. Its published merchant page lists processing in MUR, USD, GBP, EUR and JPY, with merchant account crediting after three working days. Exact commercial and technical terms for MauTaxi must still be confirmed in the merchant agreement and integration pack.

Official information:
- E-commerce acquiring: https://banking.sbmgroup.mu/merchant-corner/ecommerce
- Merchant e-commerce enquiries: ecommerce@sbmgroup.mu
- SBM merchant corner: https://banking.sbmgroup.mu/corporate/merchant-corner

## Currency plan

MauTaxi's initial customer currency plan is MUR, EUR, USD and GBP. SBM's public information also lists JPY. The actual currencies enabled for this merchant, transaction currency rules, settlement account currencies, conversion rates and fees must be confirmed in writing with SBM before checkout is enabled.

## Merchant onboarding and technical pack required

Request the following from SBM Merchant Services:
1. Merchant application requirements, approval and any travel/tourism sector conditions.
2. Merchant ID, terminal ID and any account identifiers required by the gateway.
3. Current integration guide and supported integration model (prefer bank-hosted checkout).
4. Sandbox URL, test credentials and test card scenarios.
5. Request/response examples, authentication/signature requirements and field definitions.
6. 3-D Secure behaviour, supported card schemes and challenge/failure handling.
7. Return URLs, server-to-server notification/webhook format, signature verification and retry rules.
8. Transaction query, reconciliation, void and refund API documentation.
9. Supported transaction and settlement currencies, FX rules and settlement timing for each currency.
10. Merchant discount rate, setup/monthly fees, refund fees, chargeback fees, reserve requirements and payout cut-off times.
11. PCI DSS responsibilities, website content requirements and production certification/go-live steps.

## Technical implementation contract

The Rails adapter must implement only against SBM's supplied documentation:
- Create a hosted checkout session for a server-calculated amount.
- Verify signed server-to-server notifications.
- Query a transaction independently before marking a booking paid.
- Handle idempotency, duplicate callbacks, timeouts, retries, cancellations and expired sessions.
- Support voids and full/partial refunds only where the bank's contract supports them.
- Verify merchant ID, transaction reference, booking reference, amount and currency on every successful notification or lookup.

## Currency and accounting controls

The backend is authoritative for tour prices, booking totals, payment amount and currency. Never trust browser-submitted prices or exchange rates. Each payment must preserve the charged amount/currency, the underlying MUR accounting amount, the exact trusted FX rate and quote timestamp. If an approved FX source and valid quote are not available, do not offer a foreign-currency payment amount.

## Security requirements

- Prefer SBM-hosted checkout so cardholder data never passes through MauTaxi servers.
- Never collect or store card numbers, CVV, expiry data or one-time passwords in MauTaxi forms, logs or databases.
- Store merchant credentials only in the production host's secret manager.
- Never mark a booking paid because a customer reached a success/return URL.
- Mark paid only after verified server-to-server notification or authenticated server-side transaction lookup.
- Reject replayed callbacks and mismatched merchant references, amounts, currencies or signatures.
- Maintain an audit trail and reconcile against SBM merchant reports and bank statements.

## Current implementation status

The Rails payment model, currency policy and provider adapter contract are present. The adapter deliberately fails closed because MauTaxi has not yet supplied its SBM merchant credentials, sandbox pack, API contract or webhook signing specification. No fake checkout URL, bank endpoint or payment-success response has been added. The website must keep online payment disabled until the real integration is implemented and tested.
