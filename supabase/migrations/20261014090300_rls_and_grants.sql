-- Row Level Security + explicit privileges.
--
-- Two layers protect every table:
--   1. GRANTs decide which operations/columns a client role may touch at all.
--      Moderation columns (status, verified_at, is_featured, role, ...) are
--      never granted to clients, so they can only change via SECURITY DEFINER
--      RPCs that check is_admin() / ownership themselves.
--   2. RLS policies decide which rows those operations apply to.
-- See docs/SECURITY.md for the full matrix.

-- Start from zero: Supabase grants broad table privileges by default.
revoke all on all tables in schema public from anon, authenticated;

-- ---------------------------------------------------------------------------
-- Enable RLS everywhere.
-- ---------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.neighbourhoods enable row level security;
alter table public.amenities enable row level security;
alter table public.properties enable row level security;
alter table public.property_contacts enable row level security;
alter table public.property_images enable row level security;
alter table public.property_amenities enable row level security;
alter table public.property_unavailable_dates enable row level security;
alter table public.favourites enable row level security;
alter table public.enquiries enable row level security;
alter table public.property_reports enable row level security;
alter table public.verification_checks enable row level security;
alter table public.property_status_history enable row level security;
alter table public.listing_events enable row level security;
alter table public.promotions enable row level security;

-- ---------------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------------
grant select on public.profiles to authenticated;
grant update (full_name, phone) on public.profiles to authenticated;

create policy "profiles: read own or admin"
  on public.profiles for select to authenticated
  using (id = (select auth.uid()) or (select public.is_admin()));

create policy "profiles: update own"
  on public.profiles for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- ---------------------------------------------------------------------------
-- neighbourhoods / amenities: public read, admin write.
-- ---------------------------------------------------------------------------
grant select on public.neighbourhoods, public.amenities to anon, authenticated;
grant insert, update, delete on public.neighbourhoods, public.amenities to authenticated;

create policy "neighbourhoods: read active"
  on public.neighbourhoods for select to anon, authenticated
  using (is_active or (select public.is_admin()));

create policy "neighbourhoods: admin insert"
  on public.neighbourhoods for insert to authenticated
  with check ((select public.is_admin()));

create policy "neighbourhoods: admin update"
  on public.neighbourhoods for update to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));

create policy "neighbourhoods: admin delete"
  on public.neighbourhoods for delete to authenticated
  using ((select public.is_admin()));

create policy "amenities: read active"
  on public.amenities for select to anon, authenticated
  using (is_active or (select public.is_admin()));

create policy "amenities: admin insert"
  on public.amenities for insert to authenticated
  with check ((select public.is_admin()));

create policy "amenities: admin update"
  on public.amenities for update to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));

create policy "amenities: admin delete"
  on public.amenities for delete to authenticated
  using ((select public.is_admin()));

-- ---------------------------------------------------------------------------
-- properties
-- ---------------------------------------------------------------------------
grant select on public.properties to anon, authenticated;

grant insert (
  owner_id, title, description, property_type, neighbourhood_id,
  address_or_area_description, latitude, longitude, nightly_rate,
  cleaning_fee, refundable_deposit, bedrooms, bathrooms, maximum_guests,
  minimum_nights, check_in_time, check_out_time, check_in_information,
  check_out_information, house_rules, availability_note
) on public.properties to authenticated;

grant update (
  title, description, property_type, neighbourhood_id,
  address_or_area_description, latitude, longitude, nightly_rate,
  cleaning_fee, refundable_deposit, bedrooms, bathrooms, maximum_guests,
  minimum_nights, check_in_time, check_out_time, check_in_information,
  check_out_information, house_rules, availability_note
) on public.properties to authenticated;

grant delete on public.properties to authenticated;

create policy "properties: public reads published"
  on public.properties for select to anon, authenticated
  using (status = 'published');

create policy "properties: owner reads own"
  on public.properties for select to authenticated
  using (owner_id = (select auth.uid()));

create policy "properties: admin reads all"
  on public.properties for select to authenticated
  using ((select public.is_admin()));

create policy "properties: active owner creates own"
  on public.properties for insert to authenticated
  with check (owner_id = (select auth.uid()) and (select public.is_active_owner()));

create policy "properties: owner edits own editable"
  on public.properties for update to authenticated
  using (
    owner_id = (select auth.uid())
    and status not in ('suspended', 'archived')
    and (select public.is_active_user())
  )
  with check (owner_id = (select auth.uid()));

create policy "properties: owner deletes unpublished"
  on public.properties for delete to authenticated
  using (
    owner_id = (select auth.uid())
    and status in ('draft', 'rejected')
    and approved_at is null
  );

-- ---------------------------------------------------------------------------
-- property_contacts: only the owner and admins. Guests use get_property_contact().
-- ---------------------------------------------------------------------------
grant select, insert, update, delete on public.property_contacts to authenticated;

create policy "contacts: owner or admin reads"
  on public.property_contacts for select to authenticated
  using ((select public.owns_property(property_id)) or (select public.is_admin()));

create policy "contacts: owner inserts"
  on public.property_contacts for insert to authenticated
  with check (public.can_edit_property(property_id));

create policy "contacts: owner updates"
  on public.property_contacts for update to authenticated
  using (public.can_edit_property(property_id))
  with check (public.can_edit_property(property_id));

create policy "contacts: owner deletes"
  on public.property_contacts for delete to authenticated
  using (public.can_edit_property(property_id));

-- ---------------------------------------------------------------------------
-- Child tables of a property: readable when the parent property is readable
-- (the subquery runs under the caller's RLS), writable by the editing owner.
-- ---------------------------------------------------------------------------
grant select on public.property_images, public.property_amenities, public.property_unavailable_dates to anon, authenticated;
grant insert, delete on public.property_images, public.property_amenities, public.property_unavailable_dates to authenticated;
grant update (caption, display_order, thumbnail_path, width, height) on public.property_images to authenticated;
grant update (starts_on, ends_on, note) on public.property_unavailable_dates to authenticated;

create policy "images: readable with property"
  on public.property_images for select to anon, authenticated
  using (exists (select 1 from public.properties p where p.id = property_id));

create policy "images: owner inserts"
  on public.property_images for insert to authenticated
  with check (public.can_edit_property(property_id));

create policy "images: owner updates"
  on public.property_images for update to authenticated
  using (public.can_edit_property(property_id))
  with check (public.can_edit_property(property_id));

create policy "images: owner deletes"
  on public.property_images for delete to authenticated
  using (public.can_edit_property(property_id));

create policy "property_amenities: readable with property"
  on public.property_amenities for select to anon, authenticated
  using (exists (select 1 from public.properties p where p.id = property_id));

create policy "property_amenities: owner inserts"
  on public.property_amenities for insert to authenticated
  with check (public.can_edit_property(property_id));

create policy "property_amenities: owner deletes"
  on public.property_amenities for delete to authenticated
  using (public.can_edit_property(property_id));

create policy "unavailable_dates: readable with property"
  on public.property_unavailable_dates for select to anon, authenticated
  using (exists (select 1 from public.properties p where p.id = property_id));

create policy "unavailable_dates: owner inserts"
  on public.property_unavailable_dates for insert to authenticated
  with check (public.can_edit_property(property_id));

create policy "unavailable_dates: owner updates"
  on public.property_unavailable_dates for update to authenticated
  using (public.can_edit_property(property_id))
  with check (public.can_edit_property(property_id));

create policy "unavailable_dates: owner deletes"
  on public.property_unavailable_dates for delete to authenticated
  using (public.can_edit_property(property_id));

-- ---------------------------------------------------------------------------
-- favourites: strictly private to the user.
-- ---------------------------------------------------------------------------
grant select, insert, delete on public.favourites to authenticated;

create policy "favourites: read own"
  on public.favourites for select to authenticated
  using (user_id = (select auth.uid()));

create policy "favourites: add own for published property"
  on public.favourites for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and exists (select 1 from public.properties p where p.id = property_id and p.status = 'published')
  );

create policy "favourites: remove own"
  on public.favourites for delete to authenticated
  using (user_id = (select auth.uid()));

-- ---------------------------------------------------------------------------
-- enquiries: guest sees own, owner sees enquiries for own properties.
-- Status changes go through RPCs only (no UPDATE grant).
-- ---------------------------------------------------------------------------
grant select on public.enquiries to authenticated;
grant insert (property_id, check_in, check_out, guest_count, guest_name, guest_contact, message)
  on public.enquiries to authenticated;

create policy "enquiries: guest reads own"
  on public.enquiries for select to authenticated
  using (guest_id = (select auth.uid()));

create policy "enquiries: owner reads for own properties"
  on public.enquiries for select to authenticated
  using ((select public.owns_property(property_id)));

create policy "enquiries: admin reads all"
  on public.enquiries for select to authenticated
  using ((select public.is_admin()));

create policy "enquiries: guest creates own"
  on public.enquiries for insert to authenticated
  with check (guest_id = (select auth.uid()));

-- ---------------------------------------------------------------------------
-- property_reports
-- ---------------------------------------------------------------------------
grant select on public.property_reports to authenticated;
grant insert (property_id, reason, description) on public.property_reports to authenticated;

create policy "reports: reporter reads own"
  on public.property_reports for select to authenticated
  using (reporter_id = (select auth.uid()));

create policy "reports: admin reads all"
  on public.property_reports for select to authenticated
  using ((select public.is_admin()));

create policy "reports: signed-in user reports visible property"
  on public.property_reports for insert to authenticated
  with check (
    reporter_id = (select auth.uid())
    and exists (select 1 from public.properties p where p.id = property_id and p.status = 'published')
  );

-- ---------------------------------------------------------------------------
-- Admin-only / audit tables (writes happen in SECURITY DEFINER RPCs).
-- ---------------------------------------------------------------------------
grant select on public.verification_checks, public.property_status_history,
  public.listing_events, public.promotions to authenticated;

create policy "verification_checks: admin reads"
  on public.verification_checks for select to authenticated
  using ((select public.is_admin()));

-- Owners need their own history to see rejection/suspension reasons.
create policy "status_history: owner or admin reads"
  on public.property_status_history for select to authenticated
  using ((select public.owns_property(property_id)) or (select public.is_admin()));

create policy "listing_events: admin reads"
  on public.listing_events for select to authenticated
  using ((select public.is_admin()));

create policy "promotions: admin reads"
  on public.promotions for select to authenticated
  using ((select public.is_admin()));

-- ---------------------------------------------------------------------------
-- Function privileges: nothing is executable unless granted below/later.
-- Helpers used inside policies must be executable by the policy's roles.
-- ---------------------------------------------------------------------------
revoke execute on all functions in schema public from public, anon, authenticated;

grant execute on function public.is_admin() to anon, authenticated;
grant execute on function public.is_active_user() to anon, authenticated;
grant execute on function public.is_active_owner() to authenticated;
grant execute on function public.owns_property(uuid) to anon, authenticated;
grant execute on function public.can_edit_property(uuid) to authenticated;
