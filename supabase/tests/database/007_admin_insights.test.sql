-- Admin insights: warning signs on listings and host follow-ups.
begin;
create extension if not exists pgtap with schema extensions;
select plan(16);

insert into auth.users (id, email, raw_user_meta_data) values
  ('31000000-0000-4000-a000-000000000001', 'y-admin@test.local', '{"full_name":"Ada Admin"}'),
  ('31000000-0000-4000-a000-000000000002', 'y-host1@test.local', '{"full_name":"Honest Host","intended_role":"owner"}'),
  ('31000000-0000-4000-a000-000000000003', 'y-host2@test.local', '{"full_name":"Shady Host","intended_role":"owner"}'),
  ('31000000-0000-4000-a000-000000000004', 'y-guest@test.local', '{"full_name":"Gita Guest"}');
update public.profiles set role = 'admin' where id = '31000000-0000-4000-a000-000000000001';

-- An honest published listing, plus two comparable studios for pricing.
insert into public.properties (id, owner_id, title, description, property_type, neighbourhood_id, nightly_rate,
  maximum_guests, status, approved_at, availability_confirmed_at)
select v.id::uuid, '31000000-0000-4000-a000-000000000002', v.title, 'A calm, clean studio close to shops and matatus.',
  'studio', (select id from public.neighbourhoods where slug = 'kilimani'), v.rate, 2, 'published', now(), v.confirmed
from (values
  ('32000000-0000-4000-a000-000000000001', 'Honest studio one', 4000, now() - interval '20 days'),
  ('32000000-0000-4000-a000-000000000002', 'Honest studio two', 4200, now()),
  ('32000000-0000-4000-a000-000000000003', 'Honest studio three', 4400, now())
) v(id, title, rate, confirmed);
insert into public.property_contacts (property_id, phone) values ('32000000-0000-4000-a000-000000000001', '+254711222333');

-- A suspicious pending listing by a new host.
insert into public.properties (id, owner_id, title, description, property_type, neighbourhood_id, nightly_rate,
  maximum_guests, status, submitted_at)
values ('32000000-0000-4000-a000-000000000009', '31000000-0000-4000-a000-000000000003', 'Cheap studio in Kilimani',
  'Lovely studio. Pay a deposit first via M-Pesa to secure it. Call 0722 111 444 for details.', 'studio',
  (select id from public.neighbourhoods where slug = 'kilimani'), 1500, 2, 'pending_review', now());
insert into public.property_contacts (property_id, phone) values ('32000000-0000-4000-a000-000000000009', '+254711222333');

-- Non-admins get nothing.
set local request.jwt.claims to '{"sub":"31000000-0000-4000-a000-000000000002","role":"authenticated"}';
set local role authenticated;
select throws_ok($$ select * from public.admin_listing_risks(array['32000000-0000-4000-a000-000000000009'::uuid]) $$,
  '42501', null, 'hosts cannot see warning signs');
select throws_ok($$ select public.admin_followups() $$, '42501', null, 'hosts cannot see follow-ups');
select is((select count(*)::int from public.host_nudges), 0, 'hosts cannot read reminders');

reset role;
set local request.jwt.claims to '{"sub":"31000000-0000-4000-a000-000000000001","role":"authenticated"}';
set local role authenticated;

select ok(exists (select 1 from public.admin_listing_risks(array['32000000-0000-4000-a000-000000000009'::uuid]) where code = 'shared_phone'),
  'a number shared with another host is flagged');
select ok(exists (select 1 from public.admin_listing_risks(array['32000000-0000-4000-a000-000000000009'::uuid]) where code = 'payment_words'),
  'asking for M-Pesa up front is flagged');
select ok(exists (select 1 from public.admin_listing_risks(array['32000000-0000-4000-a000-000000000009'::uuid]) where code = 'contact_in_text'),
  'a phone number in the description is flagged');
select matches((select message from public.admin_listing_risks(array['32000000-0000-4000-a000-000000000009'::uuid]) where code = 'low_price'),
  '^KES 1,500 a night is less than half the usual KES [0-9,]+ for this type of place in Kilimani',
  'bait pricing is compared with similar listings in the area');
select is((select count(*)::int from public.admin_listing_risks(array['32000000-0000-4000-a000-000000000002'::uuid])), 0,
  'an ordinary listing has no warning signs');

-- Follow-ups: stale availability and an unanswered enquiry.
reset role;
alter table public.enquiries disable trigger enquiries_validate;
insert into public.enquiries (id, property_id, guest_id, check_in, check_out, guest_count, guest_name, guest_contact, created_at)
values ('33000000-0000-4000-a000-000000000001', '32000000-0000-4000-a000-000000000002', '31000000-0000-4000-a000-000000000004',
  current_date + 5, current_date + 7, 1, 'Gita Guest', '+254733000111', now() - interval '30 hours'),
  ('33000000-0000-4000-a000-000000000002', '32000000-0000-4000-a000-000000000002', '31000000-0000-4000-a000-000000000004',
  current_date + 5, current_date + 7, 1, 'Gita Guest', '+254733000111', now() - interval '2 hours');
alter table public.enquiries enable trigger enquiries_validate;
set local role authenticated;

select ok(exists (select 1 from jsonb_array_elements(public.admin_followups() -> 'stale') s
    where s ->> 'property_id' = '32000000-0000-4000-a000-000000000001'),
  'a listing not confirmed for 20 days needs a follow-up');
select ok(exists (select 1 from jsonb_array_elements(public.admin_followups() -> 'unanswered') u
    where u ->> 'enquiry_id' = '33000000-0000-4000-a000-000000000001'),
  'an enquiry waiting 30 hours needs a follow-up');
select ok(not exists (select 1 from jsonb_array_elements(public.admin_followups() -> 'unanswered') u
    where u ->> 'enquiry_id' = '33000000-0000-4000-a000-000000000002'),
  'a 2-hour-old enquiry is not chased yet');

select lives_ok($$ select public.admin_record_nudge('32000000-0000-4000-a000-000000000002', 'enquiry', '33000000-0000-4000-a000-000000000001') $$,
  'admin records a reminder');
select ok((select u ->> 'last_nudged_at' from jsonb_array_elements(public.admin_followups() -> 'unanswered') u
    where u ->> 'enquiry_id' = '33000000-0000-4000-a000-000000000001') is not null,
  'the reminder shows on the follow-up');

-- Areas: only admins edit them; hidden areas stay readable for listings.
select lives_ok($$ insert into public.neighbourhoods (name, slug, is_active) values ('Test Hidden Area', 'test-hidden-area', false) $$,
  'admin can add an area');
reset role;
set local request.jwt.claims to '{"sub":"31000000-0000-4000-a000-000000000002","role":"authenticated"}';
set local role authenticated;
select throws_ok($$ insert into public.neighbourhoods (name, slug) values ('Host Area', 'host-area') $$,
  '42501', null, 'hosts cannot add areas');
reset role;
set local role anon;
select is((select name from public.neighbourhoods where slug = 'test-hidden-area'), 'Test Hidden Area',
  'a hidden area''s name is still readable so listings keep showing it');

select * from finish();
rollback;
