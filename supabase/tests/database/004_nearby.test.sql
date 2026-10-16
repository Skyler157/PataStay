-- "Near me" search: distance ordering, radius, privacy and input checks.
begin;
create extension if not exists pgtap with schema extensions;
select plan(6);

reset role;
set local request.jwt.claims to '{"role":"anon"}';
set local role anon;

-- From Yaya Centre (Kilimani): the seed studio there must come first.
select is(
  (select property_id from public.search_nearby(-1.2925, 36.7875, 5) limit 1),
  '10000000-0000-4000-a000-000000000001'::uuid,
  'closest listing comes first'
);
select ok(
  (select bool_and(distance_km <= 5) from public.search_nearby(-1.2925, 36.7875, 5)),
  'all results are inside the radius'
);
select ok(
  (select count(*) from public.search_nearby(-1.2925, 36.7875, 5))
    < (select count(*) from public.search_nearby(-1.2925, 36.7875, 50)),
  'a wider radius finds more listings'
);
select ok(
  not exists (select 1 from public.search_nearby(-1.2925, 36.7875, 50) n
              join public.properties p on p.id = n.property_id where p.status <> 'published'),
  'only published listings are returned'
);
select throws_ok($$ select * from public.search_nearby(-1.29, 36.78, 500) $$, '22023', null, 'radius is capped');
select throws_ok($$ select * from public.search_nearby(null, 36.78, 5) $$, '22023', null, 'location is required');

select * from finish();
rollback;
