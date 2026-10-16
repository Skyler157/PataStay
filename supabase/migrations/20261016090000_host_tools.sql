-- Phase 3: host tools.
--
-- Adds a host responsiveness signal to the public host summary: the median
-- time a host takes to answer enquiries ("Usually replies within 2 hours").
-- It is only shown once a host has answered at least 5 enquiries in the last
-- 180 days, so a single fast or slow reply cannot define a host.

drop function if exists public.get_host_summary(uuid);

create function public.get_host_summary(p_property_id uuid)
returns table (
  display_name text,
  member_since timestamptz,
  published_listings bigint,
  verified_listings bigint,
  typical_response_hours numeric,
  response_rate numeric
)
language sql
stable
security definer
set search_path = ''
as $$
  with host as (
    select pr.id, pr.full_name, pr.created_at
    from public.properties p
    join public.profiles pr on pr.id = p.owner_id
    where p.id = p_property_id
      and (p.status = 'published' or p.owner_id = auth.uid() or public.is_admin())
  ),
  recent as (
    select e.created_at, e.responded_at
    from public.enquiries e
    join public.properties p on p.id = e.property_id
    where p.owner_id = (select id from host)
      and e.created_at > now() - interval '180 days'
      and e.status <> 'cancelled'
  ),
  stats as (
    select
      count(*) filter (where responded_at is not null) as answered,
      count(*) as total,
      percentile_cont(0.5) within group (
        order by extract(epoch from (responded_at - created_at)) / 3600.0
      ) filter (where responded_at is not null) as median_hours
    from recent
  )
  select
    coalesce(nullif(split_part(trim(h.full_name), ' ', 1), ''), 'PataStay host'),
    h.created_at,
    (select count(*) from public.properties x where x.owner_id = h.id and x.status = 'published'),
    (select count(*) from public.properties x where x.owner_id = h.id and x.status = 'published' and x.verified_at is not null),
    case when s.answered >= 5 then round(s.median_hours::numeric, 1) end,
    case when s.total >= 5 then round(s.answered::numeric / s.total, 2) end
  from host h cross join stats s;
$$;

revoke execute on function public.get_host_summary(uuid) from public;
grant execute on function public.get_host_summary(uuid) to anon, authenticated;
