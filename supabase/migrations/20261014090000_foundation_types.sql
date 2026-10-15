-- PataStay foundation: extensions, enum types and generic helpers.
-- Enums are used for values that the backend must validate (status machines,
-- roles). Configurable lists (neighbourhoods, amenities) live in tables.

create extension if not exists pg_trgm with schema extensions;

create type public.user_role as enum ('guest', 'owner', 'admin');

create type public.account_status as enum ('active', 'suspended');

create type public.property_type as enum (
  'studio',
  'bedsitter',
  'one_bedroom',
  'two_bedroom',
  'three_bedroom_plus',
  'furnished_apartment',
  'serviced_apartment',
  'guest_house',
  'private_room',
  'house'
);

-- draft            owner is still editing, never public
-- pending_review   submitted, waiting for an admin, never public
-- published        approved and visible to everyone
-- rejected         admin rejected with a reason; owner may edit and resubmit
-- paused           owner temporarily hid an approved listing
-- suspended        admin hid the listing (fraud, misleading); owner cannot edit
-- archived         owner retired the listing
create type public.property_status as enum (
  'draft',
  'pending_review',
  'published',
  'rejected',
  'paused',
  'suspended',
  'archived'
);

-- An enquiry is a lead, never a reservation. "booked" only means a party
-- voluntarily reported that a stay was agreed.
create type public.enquiry_status as enum (
  'new',
  'seen',
  'available',
  'unavailable',
  'cancelled',
  'booked',
  'closed'
);

create type public.report_reason as enum (
  'scam_or_fraud',
  'misleading_photos',
  'wrong_price',
  'wrong_location',
  'not_available',
  'inappropriate_content',
  'other'
);

create type public.report_status as enum ('open', 'investigating', 'resolved', 'dismissed');

create type public.verification_check_type as enum (
  'owner_identity',
  'ownership_or_authority',
  'site_visit',
  'video_walkthrough',
  'photo_authenticity',
  'contact_verified',
  'price_confirmed'
);

create type public.verification_result as enum ('pass', 'fail', 'inconclusive');

create type public.listing_event_type as enum (
  'view',
  'share',
  'favourite_added',
  'contact_whatsapp',
  'contact_call',
  'enquiry_submitted'
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;
