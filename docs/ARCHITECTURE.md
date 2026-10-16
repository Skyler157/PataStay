# PataStay architecture

## System overview

```
 Android / iOS app (Flutter)        Admin dashboard (Flutter Web)
   guests + hosts                      administrators
        │                                   │
        └──────────── patastay_core ────────┘   shared: config, models, repositories,
                          │                      error mapping, theme, widgets
                          │ HTTPS (publishable key + user JWT)
                          ▼
                 Supabase (hosted Postgres)
   ┌────────────┬──────────────┬──────────────┬─────────────────────┐
   │ Auth       │ PostgREST    │ Storage      │ Edge Functions      │
   │ email/pass │ tables + RPC │ listing      │ (later: account     │
   │ (phone     │ guarded by   │ photos       │  deletion, emails,  │
   │  later)    │ RLS + grants │              │  payments)          │
   └────────────┴──────────────┴──────────────┴─────────────────────┘
```

There is no custom application server. Business rules that must be trusted live in Postgres: constraints, triggers, RLS and `SECURITY DEFINER` RPCs (see [SECURITY.md](SECURITY.md)). This keeps one source of truth for both apps and makes the rules testable with pgTAP.

## Flutter layering

Each feature folder separates its concerns:

| Layer | Responsibility | Example |
|---|---|---|
| `presentation/` | Widgets and screens only; read state through Riverpod | `sign_in_screen.dart` |
| providers / controllers | Riverpod `Provider`/`FutureProvider`/`Notifier` exposing state | `currentProfileProvider` |
| repositories (`patastay_core/src/data`) | The only code that calls Supabase; converts every exception to an `AppFailure` via `guard()` | `ProfileRepository` |
| models (`patastay_core/src/models`) | Immutable Freezed classes and enums whose `dbValue` mirrors Postgres enums | `Profile`, `PropertyType` |

- **Routing:** GoRouter, with one redirect function for onboarding and auth gating. Return paths are validated to prevent open redirects.
- **Errors:** UI code only sees `AppFailure` subclasses, which carry user-safe messages. Raw database errors are logged in redacted form and never displayed.
- **Configuration:** `--dart-define-from-file=env/<env>.json`. A misconfigured build shows a setup screen instead of crashing.

## Design system

Defined in `patastay_core/src/theme`, shared by both apps.

- **Colour:** lake blue (`#1E4FA3`) for trust and primary actions. It was chosen over the original acacia green because green in Kenya strongly suggests Safaricom/M-Pesa, which is confusing for an app that never takes payments. Clay (`#B9502A`) is a warm Kenyan accent used sparingly, and a sand background (`#F7F4EF`) lets white cards stand out. Verified uses a distinct teal (`#0B7A6B`) so the badge can never be mistaken for brand decoration. All text pairs meet WCAG AA contrast, and a full dark theme is included.
- **Type:** Plus Jakarta Sans (OFL), bundled rather than downloaded at runtime to save mobile data.
- **Spacing and shape:** a 4-point scale, 12 px control radius, 16 px card radius, and touch targets of at least 48 px.
- **Components:** state views (loading, empty, error with retry, offline), info banners, a busy button, form fields, property cards, price block (nightly rate plus stay total), verified/sample/freshness badges, a favourite button, and a guest stepper.

The full competitor research (Airbnb, Booking.com, Jiji, Short Stays Kenya, Kwetu, Nestaura, Bayut and others) is in the PataStay Design Benchmark page. Its Phase 2 recommendations are implemented: total-stay pricing, budget chips, Kenyan amenity filters, the contact safety sheet with a pre-filled WhatsApp message, and the `PS-xxxx` listing reference.

### Product references and lessons applied

| Reference | What we take | What we avoid |
|---|---|---|
| Airbnb | A search-first home, category chips, photo-led cards, a sticky price bar on the details page, wishlists. **Showing the total price including fees.** Airbnb added this after complaints about surprise fees. | Instant booking and payments (out of MVP scope) |
| Booking.com | Clear filters with sorting, a visible cancellation and fees summary | Urgency pressure ("only 1 left!"), which erodes trust |
| Zillow / Property24 / BuyRentKenya | "Listed / updated X days ago" freshness signals | Stale listings. We track `availability_confirmed_at` and flag listings older than 14 days |
| Local WhatsApp and Instagram rental market | Direct WhatsApp contact (what Kenyan users already expect), pre-filled with the listing reference | Fake-listing deposit scams. We review listings, verify them with evidence, re-review on contact changes, offer one-tap reporting, and remind users never to pay before confirming the place is real |

## Monetisation readiness (no payments in MVP)

- **Paid qualified enquiries:** `enquiries` plus `listing_events` (contact clicks) attribute every lead to a listing and host.
- **Commission on bookings:** `owner_reported_booking_at` and `guest_reported_booking_at` capture voluntarily reported outcomes. "Confirmed by both" is reported separately.
- **Featured listings:** `promotions` records the period and amount of every placement, and `is_featured` drives the UI.
- **Subscriptions:** can be added later as an `owner_plans` table keyed by `profiles.id` without changing existing tables.
