-- Phase 2: guest marketplace support.

-- ---------------------------------------------------------------------------
-- Short public listing reference (shown as PS-1001). Guests quote it when
-- contacting hosts so both sides know they mean the same real listing.
-- ---------------------------------------------------------------------------
alter table public.properties
  add column listing_number bigint generated always as identity (start with 1001) unique;

-- ---------------------------------------------------------------------------
-- Date-aware search. Replaces the Phase 1 signature.
-- A blocked range [starts_on, ends_on] blocks those nights (inclusive). A stay
-- [check_in, check_out) uses nights check_in .. check_out - 1.
-- ---------------------------------------------------------------------------
drop function if exists public.search_properties(
  text, uuid[], numeric, numeric, public.property_type[], integer, integer, uuid[], boolean, integer, boolean
);

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
  p_featured_only boolean default false,
  p_check_in date default null,
  p_check_out date default null
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
         or (p.is_featured and (p.featured_until is null or p.featured_until > now())))
    and (
      p_check_in is null or p_check_out is null or p_check_out <= p_check_in
      or (
        (p_check_out - p_check_in) >= p.minimum_nights
        and not exists (
          select 1 from public.property_unavailable_dates u
          where u.property_id = p.id
            and u.starts_on <= p_check_out - 1
            and u.ends_on >= p_check_in
        )
      )
    );
$$;

revoke execute on function public.search_properties(
  text, uuid[], numeric, numeric, public.property_type[], integer, integer, uuid[], boolean, integer, boolean, date, date
) from public;
grant execute on function public.search_properties(
  text, uuid[], numeric, numeric, public.property_type[], integer, integer, uuid[], boolean, integer, boolean, date, date
) to anon, authenticated;
