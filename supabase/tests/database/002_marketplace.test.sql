-- Phase 2 marketplace tests. Run with: npx supabase test db
begin;
create extension if not exists pgtap with schema extensions;

select plan(8);

insert into auth.users (id, email, raw_user_meta_data) values
  ('c0000000-0000-4000-a000-000000000001', 'm-owner@test.local', '{"full_name":"Market Owner","intended_role":"owner"}'),
  ('c0000000-0000-4000-a000-000000000002', 'm-guest@test.local', '{"full_name":"Market Guest"}');

insert into public.properties (id, owner_id, title, description, property_type, neighbourhood_id,
  nightly_rate, bedrooms, bathrooms, maximum_guests, minimum_nights, status, approved_at)
values (
  'd0000000-0000-4000-a000-000000000001', 'c0000000-0000-4000-a000-000000000001',
  'Zebra test loft', repeat('A lovely loft for testing search. ', 3), 'studio',
  (select id from public.neighbourhoods where slug = 'ngara'), 2500, 0, 1, 2, 2, 'published', now()
);

insert into public.property_unavailable_dates (property_id, starts_on, ends_on)
values ('d0000000-0000-4000-a000-000000000001', current_date + 10, current_date + 12);

select ok(
  (select listing_number from public.properties where id = 'd0000000-0000-4000-a000-000000000001') >= 1001,
  'listings get a public reference number'
);

reset role;
set local request.jwt.claims to '{"role":"anon"}';
set local role anon;

select is((select count(*)::int from public.search_properties(p_query => 'Zebra')), 1,
  'search without dates finds the listing');
select is((select count(*)::int from public.search_properties(p_query => 'Zebra',
  p_check_in => current_date + 3, p_check_out => current_date + 6)), 1,
  'free dates match');
select is((select count(*)::int from public.search_properties(p_query => 'Zebra',
  p_check_in => current_date + 9, p_check_out => current_date + 11)), 0,
  'stay overlapping a blocked night is excluded');
select is((select count(*)::int from public.search_properties(p_query => 'Zebra',
  p_check_in => current_date + 13, p_check_out => current_date + 15)), 1,
  'stay starting the day after a block is allowed');
select is((select count(*)::int from public.search_properties(p_query => 'Zebra',
  p_check_in => current_date + 8, p_check_out => current_date + 10)), 1,
  'checking out on the first blocked day is allowed');
select is((select count(*)::int from public.search_properties(p_query => 'Zebra',
  p_check_in => current_date + 3, p_check_out => current_date + 4)), 0,
  'stays shorter than the minimum are excluded');
select is((select count(*)::int from public.search_properties(p_query => 'Zebra', p_min_guests => 3)), 0,
  'guest capacity filter applies');

select * from finish();
rollback;
