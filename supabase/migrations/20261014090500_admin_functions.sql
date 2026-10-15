-- Administrator RPCs. Every function re-checks is_admin() server-side.

create or replace function public.assert_admin()
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'Administrator access required' using errcode = '42501';
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Listing moderation
-- ---------------------------------------------------------------------------
create or replace function public.admin_approve_property(p_property_id uuid, p_note text default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.assert_admin();
  perform set_config('patastay.status_reason', coalesce(nullif(trim(p_note), ''), 'Approved'), true);
  update public.properties set
    status = 'published',
    rejection_reason = null,
    approved_at = coalesce(approved_at, now()),
    published_at = now()
  where id = p_property_id and status = 'pending_review';
  if not found then
    raise exception 'Only listings pending review can be approved' using errcode = 'P0001';
  end if;
end;
$$;

create or replace function public.admin_reject_property(p_property_id uuid, p_reason text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.assert_admin();
  if p_reason is null or char_length(trim(p_reason)) < 10 then
    raise exception 'Please give the owner a clear reason (at least 10 characters)' using errcode = 'P0001';
  end if;
  perform set_config('patastay.status_reason', trim(p_reason), true);
  update public.properties set status = 'rejected', rejection_reason = trim(p_reason)
  where id = p_property_id and status = 'pending_review';
  if not found then
    raise exception 'Only listings pending review can be rejected' using errcode = 'P0001';
  end if;
end;
$$;

create or replace function public.admin_suspend_property(p_property_id uuid, p_reason text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.assert_admin();
  if p_reason is null or char_length(trim(p_reason)) < 10 then
    raise exception 'A suspension reason of at least 10 characters is required' using errcode = 'P0001';
  end if;
  perform set_config('patastay.status_reason', trim(p_reason), true);
  update public.properties set status = 'suspended', rejection_reason = trim(p_reason), is_featured = false
  where id = p_property_id and status <> 'suspended';
  if not found then
    raise exception 'Listing not found or already suspended' using errcode = 'P0001';
  end if;
end;
$$;

create or replace function public.admin_reinstate_property(p_property_id uuid, p_note text default null)
returns public.property_status
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_target public.property_status;
begin
  perform public.assert_admin();
  select case when approved_at is not null then 'published' else 'pending_review' end::public.property_status
    into v_target from public.properties where id = p_property_id and status = 'suspended';
  if v_target is null then
    raise exception 'Only suspended listings can be reinstated' using errcode = 'P0001';
  end if;
  perform set_config('patastay.status_reason', coalesce(nullif(trim(p_note), ''), 'Reinstated'), true);
  update public.properties set status = v_target, rejection_reason = null where id = p_property_id;
  return v_target;
end;
$$;

create or replace function public.admin_set_featured(
  p_property_id uuid,
  p_featured boolean,
  p_until timestamptz default null,
  p_amount_kes numeric default 0,
  p_notes text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.assert_admin();
  if p_featured then
    if not exists (select 1 from public.properties where id = p_property_id and status = 'published') then
      raise exception 'Only published listings can be featured' using errcode = 'P0001';
    end if;
    update public.properties set is_featured = true, featured_until = p_until where id = p_property_id;
    insert into public.promotions (property_id, kind, starts_at, ends_at, amount_kes, notes, created_by)
    values (p_property_id, 'featured', now(), p_until, coalesce(p_amount_kes, 0), p_notes, auth.uid());
  else
    update public.properties set is_featured = false, featured_until = null where id = p_property_id;
    update public.promotions set ends_at = now()
      where property_id = p_property_id and (ends_at is null or ends_at > now()) and starts_at < now();
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Verification
-- ---------------------------------------------------------------------------
create or replace function public.admin_record_verification_check(
  p_property_id uuid,
  p_check_type public.verification_check_type,
  p_result public.verification_result,
  p_notes text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
begin
  perform public.assert_admin();
  insert into public.verification_checks (property_id, admin_id, check_type, result, notes)
  values (p_property_id, auth.uid(), p_check_type, p_result, nullif(trim(p_notes), ''))
  returning id into v_id;
  return v_id;
end;
$$;

-- Verification badge requires passing identity, authority and a site visit or
-- video walkthrough (most recent result per check type counts).
create or replace function public.admin_set_property_verified(p_property_id uuid, p_verified boolean)
returns timestamptz
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_passed public.verification_check_type[];
begin
  perform public.assert_admin();

  if not p_verified then
    update public.properties set verified_at = null, verified_by = null where id = p_property_id;
    return null;
  end if;

  select array_agg(check_type) into v_passed from (
    select distinct on (check_type) check_type, result
    from public.verification_checks
    where property_id = p_property_id
    order by check_type, checked_at desc
  ) latest where result = 'pass';

  if v_passed is null
     or not ('owner_identity' = any (v_passed))
     or not ('ownership_or_authority' = any (v_passed))
     or not ('site_visit' = any (v_passed) or 'video_walkthrough' = any (v_passed)) then
    raise exception 'Verification requires passed checks: owner identity, ownership/authority, and a site visit or video walkthrough'
      using errcode = 'P0001';
  end if;

  update public.properties set verified_at = now(), verified_by = auth.uid() where id = p_property_id;
  return now();
end;
$$;

-- ---------------------------------------------------------------------------
-- Users
-- ---------------------------------------------------------------------------
create or replace function public.admin_set_user_role(p_user_id uuid, p_role public.user_role)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.assert_admin();
  if p_user_id = auth.uid() then
    raise exception 'Administrators cannot change their own role' using errcode = 'P0001';
  end if;
  update public.profiles set role = p_role where id = p_user_id;
  if not found then
    raise exception 'User not found' using errcode = 'P0001';
  end if;
end;
$$;

create or replace function public.admin_set_account_status(
  p_user_id uuid,
  p_status public.account_status,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.assert_admin();
  if p_user_id = auth.uid() then
    raise exception 'Administrators cannot suspend themselves' using errcode = 'P0001';
  end if;
  if p_status = 'suspended' and (p_reason is null or char_length(trim(p_reason)) < 10) then
    raise exception 'A suspension reason of at least 10 characters is required' using errcode = 'P0001';
  end if;

  update public.profiles
    set account_status = p_status,
        suspended_reason = case when p_status = 'suspended' then trim(p_reason) else null end
    where id = p_user_id;
  if not found then
    raise exception 'User not found' using errcode = 'P0001';
  end if;

  -- A suspended owner's live listings are suspended with them.
  if p_status = 'suspended' then
    perform set_config('patastay.status_reason', 'Owner account suspended: ' || trim(p_reason), true);
    update public.properties set status = 'suspended', is_featured = false
      where owner_id = p_user_id and status in ('published', 'pending_review', 'paused');
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Reports
-- ---------------------------------------------------------------------------
create or replace function public.admin_update_report(
  p_report_id uuid,
  p_status public.report_status,
  p_note text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.assert_admin();
  update public.property_reports set
    status = p_status,
    resolution_note = coalesce(nullif(trim(p_note), ''), resolution_note),
    resolved_by = case when p_status in ('resolved', 'dismissed') then auth.uid() else null end,
    resolved_at = case when p_status in ('resolved', 'dismissed') then now() else null end
  where id = p_report_id;
  if not found then
    raise exception 'Report not found' using errcode = 'P0001';
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Platform statistics (JSON so the dashboard can evolve without migrations).
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
    'promotion_revenue_kes', (select coalesce(sum(amount_kes), 0) from public.promotions where created_at >= v_since)
  );
end;
$$;

grant execute on function public.admin_approve_property(uuid, text) to authenticated;
grant execute on function public.admin_reject_property(uuid, text) to authenticated;
grant execute on function public.admin_suspend_property(uuid, text) to authenticated;
grant execute on function public.admin_reinstate_property(uuid, text) to authenticated;
grant execute on function public.admin_set_featured(uuid, boolean, timestamptz, numeric, text) to authenticated;
grant execute on function public.admin_record_verification_check(uuid, public.verification_check_type, public.verification_result, text) to authenticated;
grant execute on function public.admin_set_property_verified(uuid, boolean) to authenticated;
grant execute on function public.admin_set_user_role(uuid, public.user_role) to authenticated;
grant execute on function public.admin_set_account_status(uuid, public.account_status, text) to authenticated;
grant execute on function public.admin_update_report(uuid, public.report_status, text) to authenticated;
grant execute on function public.admin_platform_stats(integer) to authenticated;
