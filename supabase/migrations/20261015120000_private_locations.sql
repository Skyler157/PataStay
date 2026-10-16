-- Maps: keep exact locations private.
--
-- Hosts drop an exact pin into property_locations (owner/admin only). The
-- public properties.latitude/longitude are derived from it with a fixed,
-- per-listing offset of up to ~300 m, so guests see the area but not the
-- door. The offset is deterministic (from the listing id) so repeated
-- requests cannot be averaged back to the exact point. Hosts share the
-- exact address with guests directly after contact.

create table public.property_locations (
  property_id uuid primary key references public.properties (id) on delete cascade,
  latitude numeric(9, 6) not null check (latitude between -90 and 90),
  longitude numeric(9, 6) not null check (longitude between -180 and 180),
  updated_at timestamptz not null default now()
);

create trigger property_locations_set_updated_at
  before update on public.property_locations
  for each row execute function public.set_updated_at();

alter table public.property_locations enable row level security;
revoke all on public.property_locations from anon, authenticated;
grant select, insert, update, delete on public.property_locations to authenticated;

create policy "locations: owner or admin reads"
  on public.property_locations for select to authenticated
  using ((select public.owns_property(property_id)) or (select public.is_admin()));

create policy "locations: owner inserts"
  on public.property_locations for insert to authenticated
  with check (public.can_edit_property(property_id));

create policy "locations: owner updates"
  on public.property_locations for update to authenticated
  using (public.can_edit_property(property_id))
  with check (public.can_edit_property(property_id));

create policy "locations: owner deletes"
  on public.property_locations for delete to authenticated
  using (public.can_edit_property(property_id));

-- Clients can no longer write the public coordinates directly.
revoke insert (latitude, longitude), update (latitude, longitude) on public.properties from authenticated;

-- Deterministic offset of 100..300 m on each axis (random direction), from
-- the id. The minimum keeps the public point from landing on the pin.
create or replace function public.approximate_location(p_property_id uuid, p_latitude numeric, p_longitude numeric)
returns table (latitude numeric, longitude numeric)
language sql
immutable
set search_path = ''
as $$
  with h as (select md5(p_property_id::text) as d),
  offs as (
    select
      ((100 + ('x' || substr(d, 1, 8))::bit(32)::bigint % 201)
        * case when ('x' || substr(d, 17, 2))::bit(8)::int % 2 = 0 then 1 else -1 end)::numeric as north_m,
      ((100 + ('x' || substr(d, 9, 8))::bit(32)::bigint % 201)
        * case when ('x' || substr(d, 19, 2))::bit(8)::int % 2 = 0 then 1 else -1 end)::numeric as east_m
    from h
  )
  select
    round(p_latitude + north_m / 111320.0, 5),
    round(p_longitude + east_m / (111320.0 * greatest(cos(radians(p_latitude))::numeric, 0.01)), 5)
  from offs;
$$;

create or replace function public.sync_public_location()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_lat numeric;
  v_lng numeric;
begin
  if tg_op = 'DELETE' then
    update public.properties set latitude = null, longitude = null where id = old.property_id;
    return old;
  end if;
  select a.latitude, a.longitude into v_lat, v_lng
    from public.approximate_location(new.property_id, new.latitude, new.longitude) a;
  update public.properties set latitude = v_lat, longitude = v_lng where id = new.property_id;
  return new;
end;
$$;

create trigger property_locations_sync_public
  after insert or update or delete on public.property_locations
  for each row execute function public.sync_public_location();

-- Any exact coordinates entered before this migration become private.
insert into public.property_locations (property_id, latitude, longitude)
select id, latitude, longitude from public.properties
where latitude is not null and longitude is not null
on conflict (property_id) do nothing;
