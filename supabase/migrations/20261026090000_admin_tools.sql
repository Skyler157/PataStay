-- Phase 4: administration tools.
--
-- * Account deletion processing (the app promises deletion within 30 days).
-- * A log of processed deletions that holds no personal data.
-- * Admins may remove listing photos from storage during clean-up.
-- * Extra dashboard counters for deletion requests and review waiting time.

-- ---------------------------------------------------------------------------
-- Processed deletions. Only ids and counts, so the record of "we deleted this
-- account on time" survives without keeping the person's data.
-- ---------------------------------------------------------------------------
create table public.account_deletions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null, -- no foreign key: the account no longer exists
  role public.user_role not null,
  requested_at timestamptz,
  processed_at timestamptz not null default now(),
  processed_by uuid references public.profiles (id) on delete set null,
  listings_removed integer not null default 0,
  enquiries_anonymised integer not null default 0
);

create index account_deletions_processed_idx on public.account_deletions (processed_at desc);

alter table public.account_deletions enable row level security;
revoke all on public.account_deletions from anon, authenticated;
grant select on public.account_deletions to authenticated;

create policy "account_deletions: admin reads"
  on public.account_deletions for select to authenticated
  using ((select public.is_admin()));

-- ---------------------------------------------------------------------------
-- Storage: admins can list and remove listing photos (deleted accounts).
-- ---------------------------------------------------------------------------
create policy "property-images: admin reads objects"
  on storage.objects for select to authenticated
  using (bucket_id = 'property-images' and (select public.is_admin()));

create policy "property-images: admin deletes"
  on storage.objects for delete to authenticated
  using (bucket_id = 'property-images' and (select public.is_admin()));

-- ---------------------------------------------------------------------------
-- Deletes a user who asked for it. Returns the storage paths of their photos
-- so the dashboard can remove the files (SQL cannot delete storage objects).
-- ---------------------------------------------------------------------------
create or replace function public.admin_process_account_deletion(p_user_id uuid)
returns text[]
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_profile public.profiles;
  v_paths text[];
  v_listings integer;
  v_enquiries integer;
begin
  perform public.assert_admin();
  if p_user_id = auth.uid() then
    raise exception 'Administrators cannot delete their own account here' using errcode = 'P0001';
  end if;

  select * into v_profile from public.profiles where id = p_user_id for update;
  if v_profile.id is null then
    raise exception 'User not found' using errcode = 'P0001';
  end if;
  if v_profile.deletion_requested_at is null then
    raise exception 'This user has not asked for their account to be deleted' using errcode = 'P0001';
  end if;
  if v_profile.role = 'admin' then
    raise exception 'Remove the administrator role before deleting this account' using errcode = 'P0001';
  end if;

  select coalesce(array_agg(path), '{}') into v_paths from (
    select i.storage_path as path
      from public.property_images i join public.properties p on p.id = i.property_id
      where p.owner_id = p_user_id
    union
    select i.thumbnail_path
      from public.property_images i join public.properties p on p.id = i.property_id
      where p.owner_id = p_user_id and i.thumbnail_path is not null
  ) paths;

  select count(*) into v_listings from public.properties where owner_id = p_user_id;

  -- Hosts keep a record that an enquiry happened, but not who sent it.
  update public.enquiries
    set guest_name = 'Deleted user', guest_contact = 'Removed on request', message = null
    where guest_id = p_user_id;
  get diagnostics v_enquiries = row_count;

  insert into public.account_deletions (user_id, role, requested_at, processed_by, listings_removed, enquiries_anonymised)
  values (p_user_id, v_profile.role, v_profile.deletion_requested_at, auth.uid(), v_listings, v_enquiries);

  -- Cascades to the profile, listings, photos rows, contacts, favourites and
  -- sessions; other references are set to null.
  delete from auth.users where id = p_user_id;

  return v_paths;
end;
$$;

-- The user changed their mind (for example, asked support to keep the
-- account). Archived listings stay archived; the host can republish them.
create or replace function public.admin_cancel_account_deletion(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.assert_admin();
  update public.profiles set deletion_requested_at = null
    where id = p_user_id and deletion_requested_at is not null;
  if not found then
    raise exception 'No deletion request for this user' using errcode = 'P0001';
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Dashboard statistics, now with deletion requests and review waiting time.
-- ---------------------------------------------------------------------------
create or replace function public.admin_platform_stats(p_days integer default 30)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_since timestamptz := now() - make_interval(days => greatest(1, least(p_days, 365)));
begin
  perform public.assert_admin();
  return jsonb_build_object(
    'period_days', greatest(1, least(p_days, 365)),
    'users_total', (select count(*) from public.profiles),
    'owners_total', (select count(*) from public.profiles where role = 'owner'),
    'users_new', (select count(*) from public.profiles where created_at >= v_since),
    'listings_by_status', (
      select coalesce(jsonb_object_agg(status, n), '{}'::jsonb)
      from (select status, count(*) n from public.properties where not is_seed group by status) s
    ),
    'listings_pending', (select count(*) from public.properties where status = 'pending_review'),
    'pending_oldest_submitted_at', (select min(submitted_at) from public.properties where status = 'pending_review'),
    'listings_verified', (select count(*) from public.properties where verified_at is not null and status = 'published'),
    'listings_featured', (select count(*) from public.properties where is_featured and status = 'published'),
    'listings_stale', (
      select count(*) from public.properties
      where status = 'published'
        and (availability_confirmed_at is null or availability_confirmed_at < now() - interval '14 days')
    ),
    'views', (select count(*) from public.listing_events where event_type = 'view' and created_at >= v_since),
    'contact_clicks', (select count(*) from public.listing_events where event_type in ('contact_whatsapp', 'contact_call') and created_at >= v_since),
    'enquiries', (select count(*) from public.enquiries where created_at >= v_since),
    'enquiries_responded', (select count(*) from public.enquiries where created_at >= v_since and responded_at is not null),
    'bookings_reported', (
      select count(*) from public.enquiries
      where created_at >= v_since and (owner_reported_booking_at is not null or guest_reported_booking_at is not null)
    ),
    'bookings_confirmed_by_both', (
      select count(*) from public.enquiries
      where created_at >= v_since and owner_reported_booking_at is not null and guest_reported_booking_at is not null
    ),
    'reports_open', (select count(*) from public.property_reports where status in ('open', 'investigating')),
    'deletion_requests', (select count(*) from public.profiles where deletion_requested_at is not null),
    'deletion_oldest_requested_at', (select min(deletion_requested_at) from public.profiles where deletion_requested_at is not null),
    'promotion_revenue_kes', (select coalesce(sum(amount_kes), 0) from public.promotions where created_at >= v_since)
  );
end;
$$;

grant execute on function public.admin_process_account_deletion(uuid) to authenticated;
grant execute on function public.admin_cancel_account_deletion(uuid) to authenticated;
