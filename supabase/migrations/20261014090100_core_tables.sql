-- PataStay core relational schema.

-- ---------------------------------------------------------------------------
-- Profiles: one row per auth user, created by trigger (see access helpers).
-- Never publicly readable; public host details come from get_host_summary().
-- ---------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null default '' check (char_length(full_name) <= 120),
  email text,
  phone text check (phone is null or phone ~ '^\+[1-9][0-9]{7,14}$'),
  role public.user_role not null default 'guest',
  account_status public.account_status not null default 'active',
  suspended_reason text check (char_length(suspended_reason) <= 1000),
  deletion_requested_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index profiles_role_idx on public.profiles (role);
create index profiles_email_idx on public.profiles (lower(email));

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Configurable reference data.
-- ---------------------------------------------------------------------------
create table public.neighbourhoods (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 2 and 80),
  slug text not null unique check (slug ~ '^[a-z0-9-]+$'),
  city text not null default 'Nairobi',
  county text,
  latitude numeric(9, 6) check (latitude between -90 and 90),
  longitude numeric(9, 6) check (longitude between -180 and 180),
  is_popular boolean not null default false,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create index neighbourhoods_name_trgm_idx
  on public.neighbourhoods using gin (name extensions.gin_trgm_ops);

create table public.amenities (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 2 and 60),
  slug text not null unique check (slug ~ '^[a-z0-9-]+$'),
  category text not null default 'general',
  icon text,
  -- Key amenities are the ones worth showing on a compact listing card.
  is_key boolean not null default false,
  sort_order integer not null default 0,
  is_active boolean not null default true
);

-- ---------------------------------------------------------------------------
-- Properties. Drafts may be incomplete; completeness is enforced by
-- submit_property_for_review(). Status/verification/featuring columns are
-- not writable by clients (see grants) and change only through RPCs.
-- ---------------------------------------------------------------------------
create table public.properties (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  title text not null default '' check (char_length(title) <= 100),
  description text not null default '' check (char_length(description) <= 5000),
  property_type public.property_type,
  neighbourhood_id uuid references public.neighbourhoods (id) on delete restrict,
  address_or_area_description text check (char_length(address_or_area_description) <= 300),
  latitude numeric(9, 6) check (latitude between -90 and 90),
  longitude numeric(9, 6) check (longitude between -180 and 180),
  nightly_rate numeric(12, 2) check (nightly_rate > 0 and nightly_rate <= 1000000),
  currency char(3) not null default 'KES' check (currency = 'KES'),
  cleaning_fee numeric(12, 2) not null default 0 check (cleaning_fee >= 0 and cleaning_fee <= 1000000),
  refundable_deposit numeric(12, 2) not null default 0 check (refundable_deposit >= 0 and refundable_deposit <= 10000000),
  bedrooms smallint check (bedrooms between 0 and 20),
  bathrooms numeric(3, 1) check (bathrooms between 0 and 20),
  maximum_guests smallint check (maximum_guests between 1 and 30),
  minimum_nights smallint not null default 1 check (minimum_nights between 1 and 90),
  check_in_time time,
  check_out_time time,
  check_in_information text check (char_length(check_in_information) <= 1000),
  check_out_information text check (char_length(check_out_information) <= 1000),
  house_rules text check (char_length(house_rules) <= 2000),
  availability_note text check (char_length(availability_note) <= 300),
  status public.property_status not null default 'draft',
  rejection_reason text check (char_length(rejection_reason) <= 1000),
  is_featured boolean not null default false,
  featured_until timestamptz,
  verified_at timestamptz,
  verified_by uuid references public.profiles (id) on delete set null,
  availability_confirmed_at timestamptz,
  submitted_at timestamptz,
  approved_at timestamptz,
  published_at timestamptz,
  -- Development seed listings must never be mistaken for genuine listings.
  is_seed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index properties_owner_idx on public.properties (owner_id);
create index properties_status_idx on public.properties (status);
create index properties_published_price_idx on public.properties (nightly_rate) where status = 'published';
create index properties_published_created_idx on public.properties (created_at desc) where status = 'published';
create index properties_neighbourhood_idx on public.properties (neighbourhood_id) where status = 'published';
create index properties_featured_idx on public.properties (is_featured) where status = 'published' and is_featured;
create index properties_title_trgm_idx on public.properties using gin (title extensions.gin_trgm_ops);

create trigger properties_set_updated_at
  before update on public.properties
  for each row execute function public.set_updated_at();

-- Contact numbers live apart from the publicly readable listing so they can
-- only be revealed to signed-in users through get_property_contact(), which
-- records the lead and rate-limits scraping.
create table public.property_contacts (
  property_id uuid primary key references public.properties (id) on delete cascade,
  phone text not null check (phone ~ '^\+[1-9][0-9]{7,14}$'),
  whatsapp_phone text check (whatsapp_phone ~ '^\+[1-9][0-9]{7,14}$'),
  updated_at timestamptz not null default now()
);

create trigger property_contacts_set_updated_at
  before update on public.property_contacts
  for each row execute function public.set_updated_at();

create table public.property_images (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties (id) on delete cascade,
  storage_path text not null unique check (char_length(storage_path) <= 500),
  thumbnail_path text check (char_length(thumbnail_path) <= 500),
  display_order integer not null default 0 check (display_order >= 0),
  width integer check (width > 0),
  height integer check (height > 0),
  caption text check (char_length(caption) <= 200),
  created_at timestamptz not null default now(),
  constraint property_images_order_unique unique (property_id, display_order) deferrable initially deferred
);

create index property_images_property_idx on public.property_images (property_id, display_order);

create table public.property_amenities (
  property_id uuid not null references public.properties (id) on delete cascade,
  amenity_id uuid not null references public.amenities (id) on delete cascade,
  primary key (property_id, amenity_id)
);

create index property_amenities_amenity_idx on public.property_amenities (amenity_id);

-- Owner-managed blocked date ranges ("not available these dates").
create table public.property_unavailable_dates (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties (id) on delete cascade,
  starts_on date not null,
  ends_on date not null,
  note text check (char_length(note) <= 200),
  created_at timestamptz not null default now(),
  check (ends_on >= starts_on)
);

create index property_unavailable_dates_idx on public.property_unavailable_dates (property_id, starts_on);

-- ---------------------------------------------------------------------------
-- Guest activity.
-- ---------------------------------------------------------------------------
create table public.favourites (
  user_id uuid not null references public.profiles (id) on delete cascade,
  property_id uuid not null references public.properties (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, property_id)
);

create index favourites_property_idx on public.favourites (property_id);

create table public.enquiries (
  id uuid primary key default gen_random_uuid(),
  guest_id uuid default auth.uid() references public.profiles (id) on delete set null,
  property_id uuid not null references public.properties (id) on delete cascade,
  check_in date not null,
  check_out date not null,
  guest_count smallint not null check (guest_count between 1 and 30),
  guest_name text not null check (char_length(trim(guest_name)) between 2 and 120),
  guest_contact text not null check (char_length(trim(guest_contact)) between 5 and 160),
  message text check (char_length(message) <= 2000),
  status public.enquiry_status not null default 'new',
  owner_response text check (char_length(owner_response) <= 2000),
  seen_at timestamptz,
  responded_at timestamptz,
  owner_reported_booking_at timestamptz,
  guest_reported_booking_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (check_out > check_in),
  check (check_out - check_in <= 90)
);

create index enquiries_guest_idx on public.enquiries (guest_id, created_at desc);
create index enquiries_property_idx on public.enquiries (property_id, created_at desc);
create index enquiries_status_idx on public.enquiries (status);

create trigger enquiries_set_updated_at
  before update on public.enquiries
  for each row execute function public.set_updated_at();

create table public.property_reports (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties (id) on delete cascade,
  reporter_id uuid default auth.uid() references public.profiles (id) on delete set null,
  reason public.report_reason not null,
  description text check (char_length(description) <= 2000),
  status public.report_status not null default 'open',
  resolution_note text check (char_length(resolution_note) <= 2000),
  resolved_by uuid references public.profiles (id) on delete set null,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index property_reports_property_idx on public.property_reports (property_id);
create index property_reports_status_idx on public.property_reports (status, created_at desc);
-- One open report per reporter per property stops report spamming.
create unique index property_reports_one_open_per_reporter
  on public.property_reports (property_id, reporter_id)
  where status in ('open', 'investigating');

create trigger property_reports_set_updated_at
  before update on public.property_reports
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Trust, audit and analytics.
-- ---------------------------------------------------------------------------
create table public.verification_checks (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties (id) on delete cascade,
  admin_id uuid references public.profiles (id) on delete set null,
  check_type public.verification_check_type not null,
  result public.verification_result not null,
  notes text check (char_length(notes) <= 2000),
  checked_at timestamptz not null default now()
);

create index verification_checks_property_idx on public.verification_checks (property_id, checked_at desc);

create table public.property_status_history (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties (id) on delete cascade,
  from_status public.property_status,
  to_status public.property_status not null,
  changed_by uuid references public.profiles (id) on delete set null,
  reason text,
  created_at timestamptz not null default now()
);

create index property_status_history_idx on public.property_status_history (property_id, created_at desc);

create table public.listing_events (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties (id) on delete cascade,
  event_type public.listing_event_type not null,
  user_id uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now()
);

create index listing_events_property_idx on public.listing_events (property_id, event_type, created_at desc);
create index listing_events_created_idx on public.listing_events (created_at desc);
create index listing_events_user_idx on public.listing_events (user_id, created_at desc) where user_id is not null;

-- Monetisation groundwork: every featured placement is recorded with its
-- period and the amount charged (0 while featuring is free).
create table public.promotions (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties (id) on delete cascade,
  kind text not null default 'featured' check (kind in ('featured')),
  starts_at timestamptz not null default now(),
  ends_at timestamptz,
  amount_kes numeric(12, 2) not null default 0 check (amount_kes >= 0),
  notes text check (char_length(notes) <= 500),
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  check (ends_at is null or ends_at > starts_at)
);

create index promotions_property_idx on public.promotions (property_id, starts_at desc);
