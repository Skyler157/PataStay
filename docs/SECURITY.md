# PataStay security model

Authorisation is enforced **in the database**. The apps hide buttons for convenience, but every rule below holds even for someone calling the API directly with a modified client.

## Principles

1. **Two layers on every table.** `GRANT`s decide which operations and *columns* a client role may use at all. Row Level Security policies decide *which rows*.
2. **Moderation columns are never client-writable.** Clients have no update grant on `properties.status`, `verified_at`, `is_featured`, `approved_at`, `profiles.role` or `account_status`. These change only inside `SECURITY DEFINER` functions that check ownership or `is_admin()` first.
3. **Privileged functions are hardened.** Every `SECURITY DEFINER` function sets `search_path = ''` and fully qualifies names. `EXECUTE` is revoked from everyone and granted per function.
4. **No secrets in clients.** Apps receive only the Supabase URL and the publishable key. `AppConfig` refuses to start with an `sb_secret_…` or `service_role` key.
5. **Client and server validation.** Forms validate locally for fast feedback. Check constraints, triggers and RPCs re-validate everything.
6. **Least exposure of personal data.** Profiles are private. Host phone numbers live in `property_contacts` and are only released one at a time through `get_property_contact()`, which requires sign-in, logs the lead and is rate-limited (30 per hour per user). Public host information is first name, member-since date and listing counts only.

## Roles

| Role | How it is obtained |
|---|---|
| `guest` | Default for every sign-up |
| `owner` | Chosen at sign-up (`intended_role: owner`) or via `become_owner()`. Grants no rights over other users' data. |
| `admin` | Only by a database operator (SQL editor or service role) or by another admin via `admin_set_user_role()`. Sign-up metadata asking for `admin` is ignored, and admins cannot change their own role. |

Suspended accounts (`account_status = 'suspended'`) fail `is_active_user()`. They cannot create listings, enquiries or contact reveals, and suspending a host also suspends their live listings.

## Access matrix

| Table | Anonymous | Guest (signed in) | Host | Admin |
|---|---|---|---|---|
| `profiles` | none | read/update own `full_name`, `phone` | same | read all; role/status via RPC |
| `neighbourhoods`, `amenities` | read active | read active | read active | full CRUD |
| `properties` | read `published` | read `published` | + read/insert/update own (not suspended/archived); delete own unpublished drafts | read all; status, verification and featuring via RPC |
| `property_contacts` | none | via `get_property_contact()` only | own listings | read |
| `property_images`, `property_amenities`, `property_unavailable_dates` | read if parent listing is readable | same | + write own editable listings | read |
| `favourites` | none | own only | own only | none |
| `enquiries` | none | read own; insert (validated) | read for own listings; status via `owner_update_enquiry()` | read all |
| `property_reports` | none | insert for published listings; read own | same | read all; resolve via RPC |
| `verification_checks` | none | none | none | read; insert via RPC |
| `property_status_history` | none | none | own listings (shows rejection reasons) | read all |
| `listing_events` | via `track_listing_event()` (view/share) | same | aggregate counts via `owner_listing_stats()` | read all |
| `promotions` | none | none | none | read; written by `admin_set_featured()` |
| `property_locations` (exact pin) | none | none | own listings | read |
| `account_deletions` (no personal data) | none | none | none | read; written by `admin_process_account_deletion()` |

## Listing lifecycle (server-enforced)

```
draft ──submit_property_for_review()──▶ pending_review ──admin_approve_property()──▶ published ◀──▶ paused
  ▲                                         │                                         set_property_paused()
  └── owner edits & resubmits ◀── rejected ◀┘ admin_reject_property(reason)

any status ──admin_suspend_property(reason)──▶ suspended
suspended ──admin_reinstate_property()──▶ published (if previously approved) or pending_review
any except suspended ──archive_property()──▶ archived
```

- Submission requires a title (10+ characters), description (50+), type, neighbourhood, price, rooms, capacity, a contact phone and at least 3 photos.
- Changing the contact number of a live listing sends it back to `pending_review`, which blocks takeover scams.
- The verified badge (`admin_set_property_verified`) needs the latest results of these checks to be *pass*: owner identity, ownership/authority, and a site visit or video walkthrough.
- Every status change is recorded in `property_status_history` with the actor and reason.

## Search

`search_properties()` is `SECURITY INVOKER`, so RLS still limits results to published listings. When dates are given, it also excludes listings with a blocked night in the stay or a minimum stay longer than the trip. Each listing has a public `listing_number` (shown as `PS-1001`) that guests quote to hosts; it reveals nothing private.

## Enquiries

- `guest_id` and `status` are forced server-side. Clients cannot set them.
- Validation trigger: the listing must be published; the guest cannot be the host; check-in must be today or later (Nairobi time) and within 12 months; check-out must be after check-in (90 nights maximum); guest count cannot exceed capacity; the minimum stay is enforced; maximum 15 enquiries per guest per 24 hours.
- An enquiry is never a booking. `booked` means a party *reported* an agreed stay. Admin metrics separate "reported" from "confirmed by both".

## Account deletion

- `request_account_deletion()` records the request and archives the user's listings at once.
- An admin processes it with `admin_process_account_deletion()`, within the 30 days the app promises. The function refuses users who did not ask, administrator accounts (remove the role first) and the caller's own account.
- Processing deletes the auth user. This cascades to the profile, listings, photo rows, contacts, exact pins, favourites and sessions. Enquiries the person sent stay with hosts, with the name, contact and message replaced. References in reports, events and audit tables are set to null.
- The function returns the photo file paths. The dashboard then removes the files through the Storage API, using the admin delete policy, because SQL cannot delete storage objects.
- `account_deletions` keeps only the user id, role, dates and counts as proof of deletion.

## Storage

Bucket `property-images`: public read (for CDN caching; object names are random UUIDs), 5 MB limit, JPEG/PNG/WebP only. Upload, update and delete are allowed only under `{auth.uid()}/{property_id}/…` for a listing the caller can still edit (`storage_path_property_editable()`). Admins can also list and delete objects, to clean up after account deletion.

## Tests

`supabase/tests/database/001`–`006` (run with `supabase test db`) cover:
sign-up role escalation, anonymous visibility, profile and contact privacy, contact reveal requiring auth, admin RPC denial, guests editing their own role, guests creating listings, favourite and enquiry isolation, server-side enquiry validation, hosts editing status or verification, hosts editing other hosts' listings, host enquiry isolation, submission completeness, admin approval, verification prerequisites, date-aware search (blocked nights, minimum stay, capacity), private locations, host tools, the moderation round trip (reject reason, approve, feature, verify, suspend, reinstate) and account deletion (only on request, admin only, photos returned, enquiries anonymised, log kept).

When adding a table or RPC, add matching tests before shipping.

## Operational rules

- Never put the secret or service-role key in Flutter code, `env/*.json` files that ship, or the repository.
- Logs (`AppLogger`) record operation names and error types only. Emails and phone numbers are redacted, and request bodies are never logged.
- Production auth needs email confirmation turned on and custom SMTP configured.
