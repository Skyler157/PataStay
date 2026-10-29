-- Admin insights: scam warning signs for listings, and host follow-ups
-- (stale availability, unanswered enquiries) with a record of reminders.

-- ---------------------------------------------------------------------------
-- Warning signs. Each row is one reason to look closer; none of them blocks
-- anything on its own. Severity is 'high' or 'medium'.
-- ---------------------------------------------------------------------------
create or replace function public.admin_listing_risks(p_property_ids uuid[])
returns table (property_id uuid, code text, severity text, message text)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform public.assert_admin();

  return query
  with target as (
    select p.* from public.properties p where p.id = any (p_property_ids)
  ),
  -- Text a guest reads, with spaces and dashes removed for number matching.
  texts as (
    select t.id,
      lower(concat_ws(' ', t.title, t.description, t.house_rules, t.check_in_information,
        t.check_out_information, t.availability_note, t.address_or_area_description)) as body
    from target t
  )

  -- The same number is used by another host: a classic sign of one scammer
  -- running several fake accounts, or of a hijacked listing.
  select t.id, 'shared_phone', 'high',
    format('The contact number is also used by another host on %s.',
      string_agg(distinct 'PS-' || o.listing_number, ', '))
  from target t
  join public.property_contacts c on c.property_id = t.id
  join public.property_contacts oc on oc.property_id <> t.id
    and (oc.phone in (c.phone, c.whatsapp_phone) or oc.whatsapp_phone in (c.phone, c.whatsapp_phone))
  join public.properties o on o.id = oc.property_id and o.owner_id <> t.owner_id
  group by t.id

  union all
  -- Byte-identical photo files on another host's listing (copied photos).
  select t.id, 'copied_photos', 'high',
    format('%s photo%s identical to photos on another host''s listing (%s).',
      count(distinct i.id), case when count(distinct i.id) = 1 then ' is' else 's are' end,
      string_agg(distinct 'PS-' || o.listing_number, ', '))
  from target t
  join public.property_images i on i.property_id = t.id
  join storage.objects so on so.bucket_id = 'property-images' and so.name = i.storage_path
  join storage.objects so2 on so2.bucket_id = 'property-images' and so2.id <> so.id
    and so2.metadata ->> 'eTag' = so.metadata ->> 'eTag'
  join public.property_images i2 on i2.storage_path = so2.name
  join public.properties o on o.id = i2.property_id and o.owner_id <> t.owner_id
  group by t.id

  union all
  -- Asking for money up front is the most common rental scam.
  select x.id, 'payment_words', 'high',
    'The text mentions paying (M-Pesa, paybill, booking fee or deposit first). Hosts should never ask guests to pay before viewing.'
  from texts x
  where x.body ~ '(m-?pesa|pay ?bill|till (no|number)|send (the |us )?money|booking fee|pay (a |the )?(booking )?deposit (before|first|to (secure|book|reserve)))'

  union all
  -- Contact details in the text bypass the signed-in, rate-limited reveal.
  select x.id, 'contact_in_text', 'medium',
    'The text contains a phone number or email address. Ask the host to remove it; guests get the number through the Contact button.'
  from texts x
  where regexp_replace(x.body, '[\s.-]', '', 'g') ~ '(\+?254|(^|[^0-9])0)[17][0-9]{8}'
     or x.body ~ '[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}'

  union all
  -- Much cheaper than similar places: bait pricing.
  select t.id, 'low_price', 'medium',
    format('KES %s a night is less than half the usual KES %s for %s (%s similar listings).',
      to_char(t.nightly_rate, 'FM999,999,990'), to_char(cmp.median, 'FM999,999,990'), cmp.scope, cmp.n)
  from target t
  cross join lateral (
    select * from (
      select percentile_cont(0.5) within group (order by c.nightly_rate) as median, count(*) as n,
        'this type of place in ' || (select name from public.neighbourhoods where id = t.neighbourhood_id) as scope, 1 as rank
      from public.properties c
      where c.status = 'published' and c.id <> t.id and c.property_type = t.property_type
        and c.neighbourhood_id = t.neighbourhood_id
      union all
      select percentile_cont(0.5) within group (order by c.nightly_rate), count(*),
        'this type of place across Nairobi', 2
      from public.properties c
      where c.status = 'published' and c.id <> t.id and c.property_type = t.property_type
    ) options
    where options.n >= 3
    order by options.rank
    limit 1
  ) cmp
  where t.nightly_rate is not null and t.nightly_rate < cmp.median * 0.5

  union all
  -- A brand-new account whose first listing is a premium home.
  select t.id, 'new_host_premium', 'medium',
    format('New host (joined %s days ago) with no approved listings yet, listing a %s.',
      (current_date - pr.created_at::date),
      case when t.property_type in ('penthouse', 'villa', 'house')
        then replace(t.property_type::text, '_', ' ') else 'place at KES ' || to_char(t.nightly_rate, 'FM999,999,990') || ' a night' end)
  from target t
  join public.profiles pr on pr.id = t.owner_id
  where pr.created_at > now() - interval '30 days'
    and (t.property_type in ('penthouse', 'villa', 'house') or t.nightly_rate >= 20000)
    and not exists (
      select 1 from public.properties o where o.owner_id = t.owner_id and o.id <> t.id and o.approved_at is not null
    )

  union all
  -- The host's track record.
  select t.id, 'host_suspended_before', 'high',
    format('This host has %s other suspended listing%s.', count(*), case when count(*) = 1 then '' else 's' end)
  from target t
  join public.properties o on o.owner_id = t.owner_id and o.id <> t.id and o.status = 'suspended'
  group by t.id

  union all
  select t.id, 'host_reported', 'medium',
    format('Guests have reported this host''s listings %s time%s (excluding dismissed reports).',
      count(*), case when count(*) = 1 then '' else 's' end)
  from target t
  join public.properties o on o.owner_id = t.owner_id
  join public.property_reports r on r.property_id = o.id and r.status <> 'dismissed'
  group by t.id;
end;
$$;

-- ---------------------------------------------------------------------------
-- Reminders admins send to hosts (by WhatsApp, outside the app). Recorded so
-- the team does not nag the same host twice in a day.
-- ---------------------------------------------------------------------------
create table public.host_nudges (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties (id) on delete cascade,
  enquiry_id uuid references public.enquiries (id) on delete cascade,
  kind text not null check (kind in ('availability', 'enquiry')),
  nudged_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  check ((kind = 'enquiry') = (enquiry_id is not null))
);

create index host_nudges_property_idx on public.host_nudges (property_id, created_at desc);
create index host_nudges_enquiry_idx on public.host_nudges (enquiry_id) where enquiry_id is not null;

alter table public.host_nudges enable row level security;
revoke all on public.host_nudges from anon, authenticated;
grant select on public.host_nudges to authenticated;

create policy "host_nudges: admin reads"
  on public.host_nudges for select to authenticated
  using ((select public.is_admin()));

create or replace function public.admin_record_nudge(p_property_id uuid, p_kind text, p_enquiry_id uuid default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.assert_admin();
  if p_enquiry_id is not null and not exists (
    select 1 from public.enquiries where id = p_enquiry_id and property_id = p_property_id
  ) then
    raise exception 'Enquiry not found for this listing' using errcode = 'P0001';
  end if;
  insert into public.host_nudges (property_id, enquiry_id, kind, nudged_by)
  values (p_property_id, p_enquiry_id, p_kind, auth.uid());
end;
$$;

-- ---------------------------------------------------------------------------
-- Hosts to follow up: live listings whose availability is not confirmed in
-- 14+ days, and enquiries waiting 24+ hours for a reply (future stays only).
-- ---------------------------------------------------------------------------
create or replace function public.admin_followups()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_today date := (now() at time zone 'Africa/Nairobi')::date;
begin
  perform public.assert_admin();
  return jsonb_build_object(
    'stale', coalesce((
      select jsonb_agg(row_to_json(s) order by s.confirmed_at nulls first)
      from (
        select p.id as property_id, p.listing_number, p.title, p.is_seed,
          p.availability_confirmed_at as confirmed_at,
          pr.full_name as host_name, coalesce(c.whatsapp_phone, c.phone) as host_whatsapp,
          (select max(n.created_at) from public.host_nudges n
            where n.property_id = p.id and n.kind = 'availability') as last_nudged_at
        from public.properties p
        join public.profiles pr on pr.id = p.owner_id
        left join public.property_contacts c on c.property_id = p.id
        where p.status = 'published'
          and (p.availability_confirmed_at is null or p.availability_confirmed_at < now() - interval '14 days')
        limit 200
      ) s
    ), '[]'::jsonb),
    'unanswered', coalesce((
      select jsonb_agg(row_to_json(u) order by u.created_at)
      from (
        select e.id as enquiry_id, p.id as property_id, p.listing_number, p.title,
          e.created_at, e.check_in, e.check_out, e.guest_count, e.status,
          pr.full_name as host_name, coalesce(c.whatsapp_phone, c.phone) as host_whatsapp,
          (select max(n.created_at) from public.host_nudges n where n.enquiry_id = e.id) as last_nudged_at
        from public.enquiries e
        join public.properties p on p.id = e.property_id
        join public.profiles pr on pr.id = p.owner_id
        left join public.property_contacts c on c.property_id = p.id
        where e.status in ('new', 'seen')
          and e.responded_at is null
          and e.created_at < now() - interval '24 hours'
          and e.check_in >= v_today
        limit 200
      ) u
    ), '[]'::jsonb)
  );
end;
$$;

grant execute on function public.admin_listing_risks(uuid[]) to authenticated;
grant execute on function public.admin_record_nudge(uuid, text, uuid) to authenticated;
grant execute on function public.admin_followups() to authenticated;

-- ---------------------------------------------------------------------------
-- Hidden areas: listings that use them must still show their area name, so
-- area names are readable by everyone (they are not private). The app's
-- pickers and filters only offer active areas.
-- ---------------------------------------------------------------------------
drop policy "neighbourhoods: read active" on public.neighbourhoods;
create policy "neighbourhoods: readable by everyone"
  on public.neighbourhoods for select to anon, authenticated
  using (true);
