-- Access-control tests. Run with: npx supabase test db
begin;
create extension if not exists pgtap with schema extensions;

select plan(31);

-- ---------------------------------------------------------------------------
-- Fixtures (created as the postgres superuser).
-- ---------------------------------------------------------------------------
insert into auth.users (id, email, raw_user_meta_data) values
  ('a0000000-0000-4000-a000-000000000001', 't-admin@test.local', '{"full_name":"Test Admin"}'),
  ('a0000000-0000-4000-a000-000000000002', 't-owner@test.local', '{"full_name":"Test Owner","intended_role":"owner"}'),
  ('a0000000-0000-4000-a000-000000000003', 't-owner2@test.local', '{"full_name":"Other Owner","intended_role":"owner"}'),
  ('a0000000-0000-4000-a000-000000000004', 't-guest@test.local', '{"full_name":"Test Guest","intended_role":"admin"}'),
  ('a0000000-0000-4000-a000-000000000005', 't-guest2@test.local', '{"full_name":"Other Guest"}');

update public.profiles set role = 'admin' where id = 'a0000000-0000-4000-a000-000000000001';

insert into public.properties (id, owner_id, title, description, property_type, neighbourhood_id,
  nightly_rate, bedrooms, bathrooms, maximum_guests, status, approved_at)
select v.id, v.owner_id, v.title, repeat('Lovely place to stay in Nairobi. ', 3), 'studio',
  (select id from public.neighbourhoods where slug = 'kilimani'), 3000, 0, 1, 2, v.status::public.property_status,
  case when v.status = 'published' then now() end
from (values
  ('b0000000-0000-4000-a000-000000000001'::uuid, 'a0000000-0000-4000-a000-000000000002'::uuid, 'Published test studio', 'published'),
  ('b0000000-0000-4000-a000-000000000002'::uuid, 'a0000000-0000-4000-a000-000000000002'::uuid, 'Draft test studio here', 'draft'),
  ('b0000000-0000-4000-a000-000000000003'::uuid, 'a0000000-0000-4000-a000-000000000003'::uuid, 'Other owner published', 'published')
) as v(id, owner_id, title, status);

insert into public.property_contacts (property_id, phone) values
  ('b0000000-0000-4000-a000-000000000001', '+254711111111'),
  ('b0000000-0000-4000-a000-000000000002', '+254711111111'),
  ('b0000000-0000-4000-a000-000000000003', '+254722222222');

-- ---------------------------------------------------------------------------
-- Sign-up cannot grant admin.
-- ---------------------------------------------------------------------------
select is(
  (select role from public.profiles where id = 'a0000000-0000-4000-a000-000000000004'),
  'guest'::public.user_role,
  'intended_role=admin in sign-up metadata is ignored'
);
select is(
  (select role from public.profiles where id = 'a0000000-0000-4000-a000-000000000002'),
  'owner'::public.user_role,
  'intended_role=owner is honoured'
);

-- ---------------------------------------------------------------------------
-- Anonymous visitors
-- ---------------------------------------------------------------------------
reset role;
set local request.jwt.claims to '{"role":"anon"}';
set local role anon;

select is(
  (select count(*)::int from public.properties where id::text like 'b0000000%'),
  2, 'anon sees only published properties'
);
select throws_ok($$ select * from public.profiles $$, '42501', null, 'anon cannot read profiles');
select throws_ok(
  $$ select * from public.property_contacts $$,
  '42501', null, 'anon cannot read property contacts'
);
select throws_ok(
  $$ select * from public.get_property_contact('b0000000-0000-4000-a000-000000000001', 'call') $$,
  '42501', null, 'anon cannot reveal host phone numbers'
);
select is(
  (select count(*)::int from public.search_properties(p_query => 'test')),
  1, 'search matches only published listings (draft excluded)'
);
select lives_ok(
  $$ select public.track_listing_event('b0000000-0000-4000-a000-000000000001', 'view') $$,
  'anon can record a listing view'
);
select throws_ok(
  $$ select public.admin_platform_stats() $$,
  '42501', null, 'anon cannot call admin functions'
);

-- ---------------------------------------------------------------------------
-- Guest
-- ---------------------------------------------------------------------------
reset role;
set local request.jwt.claims to '{"sub":"a0000000-0000-4000-a000-000000000004","role":"authenticated"}';
set local role authenticated;

select throws_ok(
  $$ update public.profiles set role = 'admin' where id = 'a0000000-0000-4000-a000-000000000004' $$,
  '42501', null, 'guest cannot change own role'
);
select lives_ok(
  $$ update public.profiles set full_name = 'Renamed Guest' where id = 'a0000000-0000-4000-a000-000000000004' $$,
  'guest can update own name'
);
select is((select count(*)::int from public.profiles), 1, 'guest sees only own profile');

select throws_ok(
  $$ select public.admin_approve_property('b0000000-0000-4000-a000-000000000002') $$,
  '42501', null, 'guest cannot approve listings'
);
select throws_ok(
  $$ insert into public.properties (title) values ('Guest trying to list') $$,
  '42501', null, 'guest (non-owner) cannot create listings'
);

select lives_ok(
  $$ insert into public.favourites (user_id, property_id)
     values ('a0000000-0000-4000-a000-000000000004', 'b0000000-0000-4000-a000-000000000001') $$,
  'guest can favourite a published listing'
);
select throws_ok(
  $$ insert into public.favourites (user_id, property_id)
     values ('a0000000-0000-4000-a000-000000000005', 'b0000000-0000-4000-a000-000000000001') $$,
  '42501', null, 'guest cannot create favourites for someone else'
);

select lives_ok(
  $$ insert into public.enquiries (property_id, check_in, check_out, guest_count, guest_name, guest_contact)
     values ('b0000000-0000-4000-a000-000000000001', current_date + 7, current_date + 9, 2, 'Test Guest', '+254733333333') $$,
  'guest can enquire about a published listing'
);
select throws_ok(
  $$ insert into public.enquiries (property_id, check_in, check_out, guest_count, guest_name, guest_contact)
     values ('b0000000-0000-4000-a000-000000000001', current_date + 7, current_date + 9, 9, 'Test Guest', '+254733333333') $$,
  'P0001', null, 'server rejects guest count above capacity'
);
select throws_ok(
  $$ insert into public.enquiries (property_id, check_in, check_out, guest_count, guest_name, guest_contact)
     values ('b0000000-0000-4000-a000-000000000002', current_date + 7, current_date + 9, 1, 'Test Guest', '+254733333333') $$,
  'P0001', null, 'cannot enquire about an unpublished listing'
);
select is(
  (select phone from public.get_property_contact('b0000000-0000-4000-a000-000000000001', 'whatsapp')),
  '+254711111111', 'signed-in guest can reveal contact for a published listing'
);

-- ---------------------------------------------------------------------------
-- Another guest cannot see the first guest's private data.
-- ---------------------------------------------------------------------------
reset role;
set local request.jwt.claims to '{"sub":"a0000000-0000-4000-a000-000000000005","role":"authenticated"}';
set local role authenticated;
select is((select count(*)::int from public.enquiries), 0, 'guests cannot see other guests'' enquiries');
select is((select count(*)::int from public.favourites), 0, 'guests cannot see other guests'' favourites');

-- ---------------------------------------------------------------------------
-- Owner
-- ---------------------------------------------------------------------------
reset role;
set local request.jwt.claims to '{"sub":"a0000000-0000-4000-a000-000000000002","role":"authenticated"}';
set local role authenticated;

select throws_ok(
  $$ update public.properties set status = 'published' where id = 'b0000000-0000-4000-a000-000000000002' $$,
  '42501', null, 'owner cannot set listing status directly'
);
select throws_ok(
  $$ update public.properties set verified_at = now() where id = 'b0000000-0000-4000-a000-000000000001' $$,
  '42501', null, 'owner cannot self-verify a listing'
);
select lives_ok(
  $$ update public.properties set title = 'Hijacked title here' where id = 'b0000000-0000-4000-a000-000000000003' $$,
  'update on another owner''s listing silently matches no rows'
);
select is(
  (select title from public.properties where id = 'b0000000-0000-4000-a000-000000000003'),
  'Other owner published', 'owner cannot edit another owner''s listing'
);
select is(
  (select count(*)::int from public.enquiries),
  1, 'owner sees enquiries for own properties'
);
select throws_ok(
  $$ select public.submit_property_for_review('b0000000-0000-4000-a000-000000000002') $$,
  'P0001', null, 'submission requires photos and complete details'
);

reset role;
set local request.jwt.claims to '{"sub":"a0000000-0000-4000-a000-000000000003","role":"authenticated"}';
set local role authenticated;
select is((select count(*)::int from public.enquiries), 0, 'owner cannot see enquiries for other owners'' listings');

-- ---------------------------------------------------------------------------
-- Admin
-- ---------------------------------------------------------------------------
reset role;
update public.properties set status = 'pending_review' where id = 'b0000000-0000-4000-a000-000000000002';
reset role;
set local request.jwt.claims to '{"sub":"a0000000-0000-4000-a000-000000000001","role":"authenticated"}';
set local role authenticated;

select lives_ok(
  $$ select public.admin_approve_property('b0000000-0000-4000-a000-000000000002', 'Looks good') $$,
  'admin can approve a pending listing'
);
select throws_ok(
  $$ select public.admin_set_property_verified('b0000000-0000-4000-a000-000000000002', true) $$,
  'P0001', null, 'verification badge requires passed checks'
);

select * from finish();
rollback;
