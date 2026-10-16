-- "Near me": listings within a radius of the guest, closest first.
--
-- Distances use the public (approximate, 100–300 m offset) coordinates, so
-- the app shows them as "about X km away". The guest's position is only a
-- query parameter; it is never stored. Filtering reuses search_properties()
-- (SECURITY INVOKER), so RLS still limits results to published listings.
-- Returns ids + distances; the app then loads the cards by id in this order.

create or replace function public.search_nearby(
  p_latitude double precision,
  p_longitude double precision,
  p_radius_km double precision default 5,
  p_limit integer default 20,
  p_offset integer default 0,
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
  p_featured_only boolean default false,
  p_check_in date default null,
  p_check_out date default null
)
returns table (property_id uuid, distance_km numeric)
language plpgsql
stable
security invoker
set search_path = ''
as $$
begin
  if p_latitude is null or p_longitude is null
     or p_latitude not between -90 and 90 or p_longitude not between -180 and 180 then
    raise exception 'A valid location is required' using errcode = '22023';
  end if;
  if p_radius_km is null or p_radius_km < 0.5 or p_radius_km > 50 then
    raise exception 'Radius must be between 0.5 and 50 km' using errcode = '22023';
  end if;

  return query
  select d.id, round(d.km::numeric, 2)
  from (
    select p.id,
      6371 * 2 * asin(sqrt(
        power(sin(radians(p.latitude::double precision - p_latitude) / 2), 2)
        + cos(radians(p_latitude)) * cos(radians(p.latitude::double precision))
          * power(sin(radians(p.longitude::double precision - p_longitude) / 2), 2)
      )) as km
    from public.search_properties(
      p_query, p_neighbourhood_ids, p_min_price, p_max_price, p_property_types, p_min_guests,
      p_min_bedrooms, p_amenity_ids, p_verified_only, p_confirmed_within_days, p_featured_only,
      p_check_in, p_check_out
    ) p
    where p.latitude is not null and p.longitude is not null
  ) d
  where d.km <= p_radius_km
  order by d.km, d.id
  limit least(greatest(coalesce(p_limit, 20), 1), 50)
  offset greatest(coalesce(p_offset, 0), 0);
end;
$$;

revoke execute on function public.search_nearby(
  double precision, double precision, double precision, integer, integer, text, uuid[], numeric, numeric,
  public.property_type[], integer, integer, uuid[], boolean, integer, boolean, date, date
) from public;
grant execute on function public.search_nearby(
  double precision, double precision, double precision, integer, integer, text, uuid[], numeric, numeric,
  public.property_type[], integer, integer, uuid[], boolean, integer, boolean, date, date
) to anon, authenticated;
