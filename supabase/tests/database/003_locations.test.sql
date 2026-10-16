-- Exact locations stay private; the public point is approximate.
begin;
create extension if not exists pgtap with schema extensions;
select plan(7);

insert into auth.users (id, email, raw_user_meta_data) values
  ('e0000000-0000-4000-a000-000000000001', 'l-owner@test.local', '{"intended_role":"owner"}'),
  ('e0000000-0000-4000-a000-000000000002', 'l-guest@test.local', '{}');
insert into public.properties (id, owner_id, title, status, nightly_rate, approved_at)
values ('f0000000-0000-4000-a000-000000000001', 'e0000000-0000-4000-a000-000000000001', 'Pin test', 'published', 3000, now());
insert into public.property_locations (property_id, latitude, longitude)
values ('f0000000-0000-4000-a000-000000000001', -1.292300, 36.787600);

select isnt((select latitude from public.properties where id = 'f0000000-0000-4000-a000-000000000001'), -1.292300::numeric,
  'public latitude is not the exact pin');
select ok(
  (select abs(latitude - -1.2923) >= 0.0008 and abs(longitude - 36.7876) >= 0.0008
   from public.properties where id = 'f0000000-0000-4000-a000-000000000001'),
  'public point is moved at least ~90 m on both axes');
select ok(
  (select abs(latitude - -1.2923) < 0.003 and abs(longitude - 36.7876) < 0.003
   from public.properties where id = 'f0000000-0000-4000-a000-000000000001'),
  'public point stays within ~300 m of the pin');
select is(
  (select latitude from public.approximate_location('f0000000-0000-4000-a000-000000000001', -1.2923, 36.7876)),
  (select latitude from public.approximate_location('f0000000-0000-4000-a000-000000000001', -1.2923, 36.7876)),
  'offset is deterministic, so it cannot be averaged away');

reset role;
set local request.jwt.claims to '{"role":"anon"}';
set local role anon;
select throws_ok($$ select * from public.property_locations $$, '42501', null, 'anon cannot read exact locations');

reset role;
set local request.jwt.claims to '{"sub":"e0000000-0000-4000-a000-000000000002","role":"authenticated"}';
set local role authenticated;
select is((select count(*)::int from public.property_locations where property_id = 'f0000000-0000-4000-a000-000000000001'), 0,
  'guests cannot read exact locations');

reset role;
set local request.jwt.claims to '{"sub":"e0000000-0000-4000-a000-000000000001","role":"authenticated"}';
set local role authenticated;
select throws_ok(
  $$ update public.properties set latitude = 0 where id = 'f0000000-0000-4000-a000-000000000001' $$,
  '42501', null, 'owners cannot write public coordinates directly');

select * from finish();
rollback;
