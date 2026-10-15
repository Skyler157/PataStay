-- Public, guest and owner RPCs.

-- ---------------------------------------------------------------------------
-- Search (SECURITY INVOKER: RLS still applies). Returns the table type so
-- PostgREST clients can embed images/amenities and apply order + range:
--   supabase.rpc('search_properties', params: {...})
--     .select('*, property_images(*), neighbourhoods(*)')
--     .order('nightly_rate').range(0, 19)
-- ---------------------------------------------------------------------------
create or replace function public.search_properties(
  p_query text default null,
  p_neighbourhood_ids uuid[] default null,
  p_min_price numeric default null,
  p_max_price numeric default null,
  p_property_types public.property_type[] default null,
  p_min_guests integer default null,
  p_min_bedrooms integer default null,
  p_amenity_ids uuid[] default null,
  p_verified_only boolean default false,
  p_confirmed_within_days integer default null,
  p_featured_only boolean default false
)
returns setof public.properties
language sql
stable
security invoker
set search_path = ''
as $$
  with q as (
    select '%' || replace(replace(replace(trim(p_query), '\', '\\'), '%', '\%'), '_', '\_') || '%' as pattern
  )
  select p.*
  from public.properties p, q
  where p.status = 'published'
    and (
      p_query is null or trim(p_query) = ''
      or p.title ilike q.pattern
      or p.address_or_area_description ilike q.pattern
      or exists (
        select 1 from public.neighbourhoods n
        where n.id = p.neighbourhood_id and n.name ilike q.pattern
      )
    )
    and (p_neighbourhood_ids is null or cardinality(p_neighbourhood_ids) = 0
         or p.neighbourhood_id = any (p_neighbourhood_ids))
    and (p_min_price is null or p.nightly_rate >= p_min_price)
    and (p_max_price is null or p.nightly_rate <= p_max_price)
    and (p_property_types is null or cardinality(p_property_types) = 0
         or p.property_type = any (p_property_types))
    and (p_min_guests is null or p.maximum_guests >= p_min_guests)
    and (p_min_bedrooms is null or p.bedrooms >= p_min_bedrooms)
    and (p_amenity_ids is null or cardinality(p_amenity_ids) = 0 or (
      select count(distinct pa.amenity_id)
      from public.property_amenities pa
      where pa.property_id = p.id and pa.amenity_id = any (p_amenity_ids)
    ) = cardinality(p_amenity_ids))
    and (not coalesce(p_verified_only, false) or p.verified_at is not null)
    and (p_confirmed_within_days is null
         or p.availability_confirmed_at >= now() - make_interval(days => p_confirmed_within_days))
    and (not coalesce(p_featured_only, false)
         or (p.is_featured and (p.featured_until is null or p.featured_until > now())));
$$;

-- ---------------------------------------------------------------------------
-- Public host summary: first name only, never phone/email.
-- ---------------------------------------------------------------------------
create or replace function public.get_host_summary(p_property_id uuid)
returns table (
  display_name text,
  member_since timestamptz,
  published_listings bigint,
  verified_listings bigint
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    coalesce(nullif(split_part(trim(pr.full_name), ' ', 1), ''), 'PataStay host'),
    pr.created_at,
    (select count(*) from public.properties x where x.owner_id = pr.id and x.status = 'published'),
    (select count(*) from public.properties x where x.owner_id = pr.id and x.status = 'published' and x.verified_at is not null)
  from public.properties p
  join public.profiles pr on pr.id = p.owner_id
  where p.id = p_property_id
    and (p.status = 'published' or p.owner_id = auth.uid() or public.is_admin());
$$;

-- ---------------------------------------------------------------------------
-- Analytics events that anyone may record (views, shares).
-- ---------------------------------------------------------------------------
create or replace function public.track_listing_event(p_property_id uuid, p_event_type public.listing_event_type)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_event_type not in ('view', 'share') then
    raise exception 'Unsupported event type' using errcode = '22023';
  end if;

  if not exists (select 1 from public.properties where id = p_property_id and status = 'published') then
    return;
  end if;

  -- Owners viewing their own listing do not inflate stats.
  if exists (select 1 from public.properties where id = p_property_id and owner_id = auth.uid()) then
    return;
  end if;

  -- One view per signed-in user per listing per 30 minutes.
  if p_event_type = 'view' and auth.uid() is not null and exists (
    select 1 from public.listing_events
    where property_id = p_property_id and user_id = auth.uid()
      and event_type = 'view' and created_at > now() - interval '30 minutes'
  ) then
    return;
  end if;

  insert into public.listing_events (property_id, event_type, user_id)
  values (p_property_id, p_event_type, auth.uid());
end;
$$;

-- ---------------------------------------------------------------------------
-- Contact reveal: signed-in only, records the lead, rate-limited.
-- ---------------------------------------------------------------------------
create or replace function public.get_property_contact(p_property_id uuid, p_channel text)
returns table (phone text, whatsapp_phone text)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_recent integer;
begin
  if auth.uid() is null then
    raise exception 'Sign in to contact the host' using errcode = '42501';
  end if;

  if not public.is_active_user() then
    raise exception 'Your account is not active' using errcode = '42501';
  end if;

  if p_channel not in ('whatsapp', 'call') then
    raise exception 'Unsupported contact channel' using errcode = '22023';
  end if;

  if not exists (select 1 from public.properties where id = p_property_id and status = 'published') then
    raise exception 'This listing is not available' using errcode = 'P0001';
  end if;

  select count(*) into v_recent from public.listing_events
    where user_id = auth.uid()
      and event_type in ('contact_whatsapp', 'contact_call')
      and created_at > now() - interval '1 hour';

  if v_recent >= 30 then
    raise exception 'Too many contact requests. Please try again later.' using errcode = 'P0001';
  end if;

  insert into public.listing_events (property_id, event_type, user_id)
  values (
    p_property_id,
    case when p_channel = 'whatsapp' then 'contact_whatsapp'::public.listing_event_type
         else 'contact_call'::public.listing_event_type end,
    auth.uid()
  );

  return query
    select c.phone, coalesce(c.whatsapp_phone, c.phone)
    from public.property_contacts c
    where c.property_id = p_property_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- Account
-- ---------------------------------------------------------------------------
create or replace function public.become_owner()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Not signed in' using errcode = '42501';
  end if;
  update public.profiles
    set role = 'owner'
    where id = auth.uid() and role = 'guest' and account_status = 'active';
end;
$$;

create or replace function public.request_account_deletion()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Not signed in' using errcode = '42501';
  end if;
  update public.profiles set deletion_requested_at = now() where id = auth.uid();
  -- Hide the user's listings immediately; data is removed when the request is processed.
  perform set_config('patastay.status_reason', 'Owner requested account deletion', true);
  update public.properties set status = 'archived'
    where owner_id = auth.uid() and status not in ('suspended', 'archived');
end;
$$;

-- ---------------------------------------------------------------------------
-- Owner listing lifecycle
-- ---------------------------------------------------------------------------
create or replace function public.submit_property_for_review(p_property_id uuid)
returns public.property_status
language plpgsql
security definer
set search_path = ''
as $$
declare
  v public.properties;
  v_missing text[] := '{}';
  v_images integer;
begin
  select * into v from public.properties where id = p_property_id for update;

  if v.id is null or v.owner_id <> auth.uid() then
    raise exception 'Listing not found' using errcode = '42501';
  end if;
  if not public.is_active_owner() then
    raise exception 'Your account cannot submit listings' using errcode = '42501';
  end if;
  if v.status not in ('draft', 'rejected') then
    raise exception 'Only drafts or rejected listings can be submitted (current status: %)', v.status
      using errcode = 'P0001';
  end if;

  if char_length(trim(v.title)) < 10 then v_missing := array_append(v_missing, 'a title of at least 10 characters'); end if;
  if char_length(trim(v.description)) < 50 then v_missing := array_append(v_missing, 'a description of at least 50 characters'); end if;
  if v.property_type is null then v_missing := array_append(v_missing, 'property type'); end if;
  if v.neighbourhood_id is null then v_missing := array_append(v_missing, 'neighbourhood'); end if;
  if v.nightly_rate is null then v_missing := array_append(v_missing, 'nightly rate'); end if;
  if v.bedrooms is null then v_missing := array_append(v_missing, 'number of bedrooms'); end if;
  if v.bathrooms is null then v_missing := array_append(v_missing, 'number of bathrooms'); end if;
  if v.maximum_guests is null then v_missing := array_append(v_missing, 'maximum guests'); end if;
  if not exists (select 1 from public.property_contacts where property_id = v.id) then
    v_missing := array_append(v_missing, 'contact phone number');
  end if;
  select count(*) into v_images from public.property_images where property_id = v.id;
  if v_images < 3 then v_missing := array_append(v_missing, 'at least 3 photos'); end if;

  if cardinality(v_missing) > 0 then
    raise exception 'Listing incomplete. Please add: %', array_to_string(v_missing, ', ')
      using errcode = 'P0001';
  end if;

  perform set_config('patastay.status_reason', 'Submitted by owner', true);
  update public.properties
    set status = 'pending_review', submitted_at = now(), rejection_reason = null
    where id = v.id;
  return 'pending_review';
end;
$$;

create or replace function public.set_property_paused(p_property_id uuid, p_paused boolean)
returns public.property_status
language plpgsql
security definer
set search_path = ''
as $$
declare
  v public.properties;
begin
  select * into v from public.properties where id = p_property_id for update;
  if v.id is null or v.owner_id <> auth.uid() or not public.is_active_user() then
    raise exception 'Listing not found' using errcode = '42501';
  end if;

  if p_paused then
    if v.status <> 'published' then
      raise exception 'Only published listings can be paused' using errcode = 'P0001';
    end if;
    perform set_config('patastay.status_reason', 'Paused by owner', true);
    update public.properties set status = 'paused' where id = v.id;
    return 'paused';
  else
    if v.status <> 'paused' or v.approved_at is null then
      raise exception 'Only paused, previously approved listings can be resumed' using errcode = 'P0001';
    end if;
    perform set_config('patastay.status_reason', 'Resumed by owner', true);
    update public.properties set status = 'published', published_at = now() where id = v.id;
    return 'published';
  end if;
end;
$$;

create or replace function public.archive_property(p_property_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform set_config('patastay.status_reason', 'Archived by owner', true);
  update public.properties set status = 'archived'
    where id = p_property_id and owner_id = auth.uid() and status not in ('suspended', 'archived');
  if not found then
    raise exception 'Listing cannot be archived' using errcode = 'P0001';
  end if;
end;
$$;

create or replace function public.confirm_property_availability(p_property_id uuid, p_note text default null)
returns timestamptz
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_now timestamptz := now();
begin
  if char_length(p_note) > 300 then
    raise exception 'Availability note is too long' using errcode = '22001';
  end if;
  update public.properties
    set availability_confirmed_at = v_now,
        availability_note = coalesce(nullif(trim(p_note), ''), availability_note)
    where id = p_property_id and public.can_edit_property(p_property_id);
  if not found then
    raise exception 'Listing not found' using errcode = '42501';
  end if;
  return v_now;
end;
$$;

-- Reorders images atomically; p_image_ids must list every image of the property.
create or replace function public.reorder_property_images(p_property_id uuid, p_image_ids uuid[])
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.can_edit_property(p_property_id) then
    raise exception 'Listing not found' using errcode = '42501';
  end if;
  if (select count(*) from public.property_images where property_id = p_property_id)
     <> cardinality(p_image_ids)
     or exists (
       select 1 from unnest(p_image_ids) as i(id)
       where not exists (select 1 from public.property_images pi where pi.id = i.id and pi.property_id = p_property_id)
     ) then
    raise exception 'Image list does not match this listing' using errcode = '22023';
  end if;

  update public.property_images pi
    set display_order = o.ord - 1
    from unnest(p_image_ids) with ordinality as o(id, ord)
    where pi.id = o.id;
end;
$$;

-- ---------------------------------------------------------------------------
-- Enquiry lifecycle
-- ---------------------------------------------------------------------------
create or replace function public.owner_update_enquiry(
  p_enquiry_id uuid,
  p_status public.enquiry_status,
  p_response text default null
)
returns public.enquiry_status
language plpgsql
security definer
set search_path = ''
as $$
declare
  v public.enquiries;
begin
  select e.* into v from public.enquiries e
    join public.properties p on p.id = e.property_id
    where e.id = p_enquiry_id and p.owner_id = auth.uid()
    for update of e;

  if v.id is null then
    raise exception 'Enquiry not found' using errcode = '42501';
  end if;
  if p_status not in ('seen', 'available', 'unavailable', 'booked', 'closed') then
    raise exception 'Owners cannot set status %', p_status using errcode = '22023';
  end if;
  if v.status = 'cancelled' then
    raise exception 'The guest cancelled this enquiry' using errcode = 'P0001';
  end if;
  if char_length(p_response) > 2000 then
    raise exception 'Response is too long' using errcode = '22001';
  end if;
  -- "seen" never downgrades a more advanced status.
  if p_status = 'seen' and v.status <> 'new' then
    return v.status;
  end if;

  update public.enquiries set
    status = p_status,
    owner_response = coalesce(nullif(trim(p_response), ''), owner_response),
    seen_at = coalesce(seen_at, now()),
    responded_at = case when p_status in ('available', 'unavailable') then coalesce(responded_at, now()) else responded_at end,
    owner_reported_booking_at = case when p_status = 'booked' then now() else owner_reported_booking_at end
  where id = v.id;

  return p_status;
end;
$$;

create or replace function public.guest_update_enquiry(p_enquiry_id uuid, p_action text)
returns public.enquiry_status
language plpgsql
security definer
set search_path = ''
as $$
declare
  v public.enquiries;
begin
  select * into v from public.enquiries where id = p_enquiry_id and guest_id = auth.uid() for update;
  if v.id is null then
    raise exception 'Enquiry not found' using errcode = '42501';
  end if;

  if p_action = 'cancel' then
    if v.status in ('cancelled', 'booked', 'closed') then
      raise exception 'This enquiry can no longer be cancelled' using errcode = 'P0001';
    end if;
    update public.enquiries set status = 'cancelled' where id = v.id;
    return 'cancelled';
  elsif p_action = 'report_booked' then
    if v.status in ('cancelled', 'unavailable') then
      raise exception 'This enquiry cannot be marked as booked' using errcode = 'P0001';
    end if;
    update public.enquiries set status = 'booked', guest_reported_booking_at = now() where id = v.id;
    return 'booked';
  else
    raise exception 'Unsupported action' using errcode = '22023';
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Owner statistics (per listing). Counts only, no personal data.
-- ---------------------------------------------------------------------------
create or replace function public.owner_listing_stats()
returns table (
  property_id uuid,
  views bigint,
  contact_clicks bigint,
  favourites bigint,
  enquiries bigint,
  new_enquiries bigint
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    p.id,
    (select count(*) from public.listing_events e where e.property_id = p.id and e.event_type = 'view'),
    (select count(*) from public.listing_events e where e.property_id = p.id and e.event_type in ('contact_whatsapp', 'contact_call')),
    (select count(*) from public.favourites f where f.property_id = p.id),
    (select count(*) from public.enquiries q where q.property_id = p.id),
    (select count(*) from public.enquiries q where q.property_id = p.id and q.status = 'new')
  from public.properties p
  where p.owner_id = auth.uid();
$$;

grant execute on function public.search_properties(text, uuid[], numeric, numeric, public.property_type[], integer, integer, uuid[], boolean, integer, boolean) to anon, authenticated;
grant execute on function public.get_host_summary(uuid) to anon, authenticated;
grant execute on function public.track_listing_event(uuid, public.listing_event_type) to anon, authenticated;
grant execute on function public.get_property_contact(uuid, text) to authenticated;
grant execute on function public.become_owner() to authenticated;
grant execute on function public.request_account_deletion() to authenticated;
grant execute on function public.submit_property_for_review(uuid) to authenticated;
grant execute on function public.set_property_paused(uuid, boolean) to authenticated;
grant execute on function public.archive_property(uuid) to authenticated;
grant execute on function public.confirm_property_availability(uuid, text) to authenticated;
grant execute on function public.reorder_property_images(uuid, uuid[]) to authenticated;
grant execute on function public.owner_update_enquiry(uuid, public.enquiry_status, text) to authenticated;
grant execute on function public.guest_update_enquiry(uuid, text) to authenticated;
grant execute on function public.owner_listing_stats() to authenticated;
