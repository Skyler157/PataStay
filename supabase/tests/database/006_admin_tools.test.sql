-- Administration: moderation round trip, verification rules, user
-- management and account deletion processing.
begin;
create extension if not exists pgtap with schema extensions;
select plan(20);

insert into auth.users (id, email, raw_user_meta_data) values
  ('21000000-0000-4000-a000-000000000001', 'x-admin@test.local', '{"full_name":"Ada Admin"}'),
  ('21000000-0000-4000-a000-000000000002', 'x-host@test.local', '{"full_name":"Hassan Host","intended_role":"owner"}'),
  ('21000000-0000-4000-a000-000000000003', 'x-guest@test.local', '{"full_name":"Grace Guest"}');
update public.profiles set role = 'admin' where id = '21000000-0000-4000-a000-000000000001';

insert into public.properties (id, owner_id, title, description, property_type, neighbourhood_id, nightly_rate,
  bedrooms, bathrooms, maximum_guests, status, submitted_at)
values ('22000000-0000-4000-a000-000000000001', '21000000-0000-4000-a000-000000000002',
  'Quiet studio off Ngong Road', repeat('Quiet, clean and close to town. ', 3), 'studio',
  (select id from public.neighbourhoods where slug = 'kilimani'), 3500, 0, 1, 2, 'pending_review', now());
insert into public.property_images (property_id, storage_path, thumbnail_path, display_order) values
  ('22000000-0000-4000-a000-000000000001', '21000000-0000-4000-a000-000000000002/22000000-0000-4000-a000-000000000001/a.jpg',
   '21000000-0000-4000-a000-000000000002/22000000-0000-4000-a000-000000000001/a_t.jpg', 0),
  ('22000000-0000-4000-a000-000000000001', '21000000-0000-4000-a000-000000000002/22000000-0000-4000-a000-000000000001/b.jpg', null, 1);

-- Moderation as the admin.
set local request.jwt.claims to '{"sub":"21000000-0000-4000-a000-000000000001","role":"authenticated"}';
set local role authenticated;

select ok((select (public.admin_platform_stats(30) ->> 'listings_pending')::int >= 1), 'stats count listings waiting for review');
select throws_ok($$ select public.admin_reject_property('22000000-0000-4000-a000-000000000001', 'Too short') $$,
  'P0001', null, 'a rejection needs a clear reason');
select lives_ok($$ select public.admin_reject_property('22000000-0000-4000-a000-000000000001', 'Please add a photo of the bathroom.') $$,
  'admin can reject with a reason');
select is((select reason from public.property_status_history
  where property_id = '22000000-0000-4000-a000-000000000001' order by created_at desc, to_status desc limit 1),
  'Please add a photo of the bathroom.', 'the reason is kept in the history');

-- The host resubmits; the admin approves, features and verifies.
reset role;
update public.properties set status = 'pending_review' where id = '22000000-0000-4000-a000-000000000001';
set local role authenticated;
select lives_ok($$ select public.admin_approve_property('22000000-0000-4000-a000-000000000001') $$, 'admin can approve');
select lives_ok($$ select public.admin_set_featured('22000000-0000-4000-a000-000000000001', true, now() + interval '7 days', 500, 'Launch week') $$,
  'admin can feature a live listing');
select throws_ok($$ select public.admin_set_property_verified('22000000-0000-4000-a000-000000000001', true) $$,
  'P0001', null, 'verification needs the required checks first');
select lives_ok($$
  select public.admin_record_verification_check('22000000-0000-4000-a000-000000000001', 'owner_identity', 'pass', 'National ID seen');
  select public.admin_record_verification_check('22000000-0000-4000-a000-000000000001', 'ownership_or_authority', 'pass', 'Lease letter');
  select public.admin_record_verification_check('22000000-0000-4000-a000-000000000001', 'video_walkthrough', 'pass', null);
$$, 'admin records verification checks');
select ok(public.admin_set_property_verified('22000000-0000-4000-a000-000000000001', true) is not null,
  'listing can be verified once checks pass');
select lives_ok($$ select public.admin_suspend_property('22000000-0000-4000-a000-000000000001', 'Guests report a fake address.') $$,
  'admin can suspend');
select is((select is_featured from public.properties where id = '22000000-0000-4000-a000-000000000001'), false,
  'suspending removes featuring');
select is(public.admin_reinstate_property('22000000-0000-4000-a000-000000000001'), 'published'::public.property_status,
  'a previously approved listing is reinstated as published');

-- Account deletion.
select throws_ok($$ select public.admin_process_account_deletion('21000000-0000-4000-a000-000000000002') $$,
  'P0001', 'This user has not asked for their account to be deleted', 'only requested deletions can be processed');

reset role;
set local request.jwt.claims to '{"sub":"21000000-0000-4000-a000-000000000003","role":"authenticated"}';
insert into public.enquiries (property_id, guest_id, check_in, check_out, guest_count, guest_name, guest_contact, message)
values ('22000000-0000-4000-a000-000000000001', '21000000-0000-4000-a000-000000000003', current_date + 10, current_date + 12,
  1, 'Grace Guest', '+254722111333', 'Is parking available?');
set local request.jwt.claims to '{"sub":"21000000-0000-4000-a000-000000000002","role":"authenticated"}';
set local role authenticated;
select lives_ok($$ select public.request_account_deletion() $$, 'host asks for deletion');

reset role;
set local request.jwt.claims to '{"sub":"21000000-0000-4000-a000-000000000002","role":"authenticated"}';
set local role authenticated;
select throws_ok($$ select public.admin_process_account_deletion('21000000-0000-4000-a000-000000000002') $$,
  '42501', null, 'non-admins cannot process deletions');

reset role;
set local request.jwt.claims to '{"sub":"21000000-0000-4000-a000-000000000001","role":"authenticated"}';
set local role authenticated;
select is(cardinality(public.admin_process_account_deletion('21000000-0000-4000-a000-000000000002')), 3,
  'processing returns every photo file to remove');
select is((select count(*)::int from public.properties where id = '22000000-0000-4000-a000-000000000001'), 0,
  'the host''s listings are gone');
select is((select listings_removed from public.account_deletions where user_id = '21000000-0000-4000-a000-000000000002'), 1,
  'the deletion is logged without personal data');

-- Guest deletion anonymises their enquiries for hosts.
reset role;
insert into public.properties (id, owner_id, title, status) values
  ('22000000-0000-4000-a000-000000000002', '21000000-0000-4000-a000-000000000001', 'Admin test listing', 'published');
-- Insert directly: the validation trigger would attribute it to the caller.
alter table public.enquiries disable trigger enquiries_validate;
insert into public.enquiries (id, property_id, guest_id, check_in, check_out, guest_count, guest_name, guest_contact, message)
values ('23000000-0000-4000-a000-000000000001', '22000000-0000-4000-a000-000000000002', '21000000-0000-4000-a000-000000000003',
  current_date + 3, current_date + 4, 1, 'Grace Guest', '+254722111333', 'Hello');
alter table public.enquiries enable trigger enquiries_validate;
update public.profiles set deletion_requested_at = now() where id = '21000000-0000-4000-a000-000000000003';
set local role authenticated;
select lives_ok($$ select public.admin_process_account_deletion('21000000-0000-4000-a000-000000000003') $$,
  'admin processes a guest''s deletion');
select is((select guest_name || ' / ' || guest_contact || ' / ' || coalesce(message, '-') from public.enquiries
  where id = '23000000-0000-4000-a000-000000000001'),
  'Deleted user / Removed on request / -', 'the guest''s name, contact and message are removed from enquiries');

select * from finish();
rollback;
