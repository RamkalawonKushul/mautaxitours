# MauTaxi Tours — SEO launch checklist

This guide covers the account and business-owner steps that cannot be completed safely from repository code alone.

## 1. Google Search Console

1. Open Google Search Console and add a **Domain** property for `mautaxitours.com`.
2. Copy the TXT verification record Google gives you and add it to the domain's DNS records.
3. Complete verification, then submit `https://www.mautaxitours.com/sitemap.xml`.
4. Use URL Inspection for the homepage and the direct interactive tour URLs (`/platform/tour.html?id=...`). Request indexing after the public website is deployed. Tour detail pages carry their own titles, descriptions, canonical URLs and TouristTrip structured data; older duplicate tour URLs are marked noindex and canonicalised to the direct booking pages.
5. Check Page indexing, Core Web Vitals, HTTPS, and Mobile Usability reports regularly. Fix errors rather than repeatedly requesting indexing.

## 2. Google Business Profile

1. Claim or create the genuine MauTaxi Tours business profile using the business's real-world name and accurate contact details.
2. Choose the closest accurate primary category for the service actually provided. Add only relevant secondary categories.
3. If customers are not served at a staffed public address, configure the profile as a service-area business and hide the private address. Do not invent an office or use an address where customers cannot visit.
4. Set service areas accurately; add real operating hours, phone, website, WhatsApp/booking link, and current photographs.
5. Ask genuine customers for honest reviews after completed journeys. Never buy reviews, offer rewards for positive reviews, or create reviews from staff/family.
6. Reply professionally to all reviews and keep profile information consistent with the website.

## 3. Analytics and booking measurement

Before adding analytics code, create a Google Analytics 4 property and a web data stream for the final canonical domain. Keep the Measurement ID in the site's deployment configuration; never commit private credentials.

Track at least:
- Tour detail views
- Add-to-trip actions
- Booking form starts and submissions
- WhatsApp clicks
- Transfer enquiry submissions
- Confirmed bookings and actual revenue, once booking persistence/payment are live

Do not count a WhatsApp click or an unconfirmed enquiry as a completed sale. Configure Google Ads conversion imports only after real booking events can be measured.

## 4. Google Ads

Start with tightly targeted, high-intent campaigns after the website is live:
- Mauritius airport transfer / airport taxi
- Private tours in Mauritius
- Ile aux Cerfs speedboat trips
- Ile aux Gabriel catamaran trips
- Group transport Mauritius

Send each ad to the most relevant existing tour or service page in the same direct booking journey. Use location targeting relevant to likely visitors, negative keywords, and a clear daily budget. Measure qualified enquiries and confirmed bookings, not just clicks. Do not advertise prices or inclusions that are not currently honoured.

## 5. Content and trust

- Add original, current photographs from actual MauTaxi Tours journeys where possible.
- Keep every tour's duration, itinerary, pickup areas, price, inclusions and exclusions accurate.
- Publish helpful answers to real visitor questions; avoid duplicate or thin pages made only to repeat keywords.
- Keep contact details, service areas and business claims consistent.
- Do not publish invented ratings, testimonials, customer counts, awards or guarantees.

## 6. Technical release checks

- Deploy the reviewed `platform-modernization` branch only after owner approval.
- Verify the custom domain serves the intended homepage and direct interactive tour URLs over HTTPS.
- Test every tour link, image, WhatsApp action, booking enquiry, mobile layout and form on real devices.
- Recheck the sitemap and robots file on the live domain.
- The Rails API, booking database, administrator CMS and SBM card checkout must be deployed and tested separately before describing online card payment or instant booking as available.

## 7. Ongoing review

Every month, review Search Console queries and pages, Google Business Profile calls/directions/website clicks, paid campaign cost per qualified enquiry, and confirmed bookings. Improve pages based on real search terms and customer questions.
