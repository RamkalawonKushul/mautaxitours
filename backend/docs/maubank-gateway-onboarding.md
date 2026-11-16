# MauBank gateway integration — onboarding checklist

## Decision
MauTaxi Tours will use MauBank as its primary business bank and the intended first card-acquiring provider. The Rails integration is deliberately provider-adapter based. No gateway endpoint, request signature, callback format, or credential name is assumed until MauBank supplies its merchant integration pack.

## Currency plan
Customer-facing currency choices requested for the platform:
- MUR
- EUR
- USD
- GBP

These are the target currencies, not a claim that MauBank has approved all four for card acceptance or settlement. Confirm the exact transaction currencies, settlement currencies, conversion rules, and account destinations with MauBank before enabling them.

All tour prices remain authoritative in the database. The server must create an immutable currency quote for each payment, recording:
- amount and currency charged to the customer;
- original MUR amount;
- exact FX rate used and quote timestamp;
- booking and payment references.

Never accept a total, exchange rate, or currency conversion supplied by the browser as authoritative. If a fresh trusted rate is unavailable, do not create a foreign-currency checkout; offer MUR or manual confirmation instead.

## Questions for MauBank Merchant Services
1. Does MauBank currently onboard Mauritian SMEs for e-commerce card acquiring?
2. Can a MauBank business-account holder obtain a merchant account and hosted payment page?
3. Which international card schemes are accepted (Visa, Mastercard, American Express, Diners, JCB)?
4. Which transaction currencies are supported: MUR, EUR, USD and GBP?
5. Which currencies can be settled, and can proceeds be credited to corresponding MauBank foreign-currency accounts?
6. What are the acquiring, settlement, FX, refund and chargeback fees and settlement times?
7. Does the solution support 3-D Secure 2, hosted checkout, partial refunds, voids and recurring payments?
8. Provide current API/SDK documentation, sandbox URL, test merchant credentials, webhook signing specification, IP ranges (if applicable), retry policy and transaction-query endpoint.
9. Confirm PCI DSS responsibilities and any required website, terms, privacy, cancellation and refund-policy checks.
10. Provide technical support and production go-live procedures.

## Required technical contract before adapter implementation
- Create checkout session / payment intent
- Retrieve transaction by provider reference
- Verify signed server-to-server notification
- Idempotent payment creation and notification processing
- Void and full/partial refund
- Currency and amount echoed in verified transaction details
- Explicit statuses for authorised, captured, declined, cancelled, expired and refunded

## Security and accounting rules
- Use a bank-hosted checkout page where available; card data must never pass through or be stored by MauTaxi.
- Store merchant credentials only in the deployment host's secret manager, never in Git or browser code.
- Mark a booking paid only after a verified server-to-server event or an authenticated server-side transaction lookup confirms the exact amount and currency.
- Do not trust the customer's return/thank-you URL as proof of payment.
- Reject mismatched booking references, amounts, currencies, merchant IDs, signatures and replayed events.
- Keep an audit trail of status transitions and provider references. Do not store CVV, PAN, expiry data or unnecessary cardholder data.
- Reconcile daily against MauBank's merchant report and bank statement.
- Refunds must reference the original captured payment and be recorded separately from the original payment.

## Current implementation boundary
The Rails branch contains the payment persistence model, currency validation and a gateway adapter contract. The live MauBank HTTP integration is intentionally not implemented until MauBank supplies its actual API and sandbox details. This avoids inventing endpoints or accidentally sending real transactions to an unverified service.
