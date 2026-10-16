-- Host tools: draft lifecycle, photos, contacts, enquiry replies and the
-- response-time signal, exercised as the host would through the API.
begin;
create extension if not exists pgtap with schema extensions;
select plan(16);

insert into auth.users (id, email, raw_user_meta_data) values
  ('11000000-0000-4000-a000-000000000001', 'h-owner@test.local', '{"full_name":"Halima Host","intended_role":"owner"}'),
  ('11000000-0000-4000-a000-000000000002', 'h-other@test.local', '{"intended_role":"owner"}'),
  ('11000000-0000-4000-a000-000000000003', 'h-guest@test.local', '{"full_name":"Gabriel Guest"}');

-- The host creates and fills a draft.
reset role;
set local request.jwt.claims to '{"sub":"11000000-0000-4000-a000-000000000001","role":"authenticated"}';
set local role authenticated;

select lives_ok($$
  insert into public.properties (id, title) values ('12000000-0000-4000-a000-000000000001', '')
$$, 'host can create an empty draft');
select is((select status from public.properties where id = '12000000-0000-4000-a000-000000000001'),
  'draft'::public.property_status, 'new listings start as drafts');
select is((select owner_id from public.properties where id = '12000000-0000-4000-a000-000000000001'),
  '11000000-0000-4000-a000-000000000001'::uuid, 'owner is the signed-in host');

select lives_ok($$
  update public.properties set
    title = 'Sunny one-bedroom near Junction Mall',
    description = repeat('Clean, quiet and close to shops and matatus. ', 3),
    property_type = 'one_bedroom',
    neighbourhood_id = (select id from public.neighbourhoods where slug = 'kilimani'),
    nightly_rate = 4500, bedrooms = 1, bathrooms = 1, maximum_guests = 2
  where id = '12000000-0000-4000-a000-000000000001'
$$, 'host can fill in draft details');

select lives_ok($$
  insert into public.property_contacts (property_id, phone, whatsapp_phone)
  values ('12000000-0000-4000-a000-000000000001', '+254711000111', '+254711000111')
$$, 'host can add a contact number');

select throws_ok($$ select public.submit_property_for_review('12000000-0000-4000-a000-000000000001') $$,
  'P0001', 'Listing incomplete. Please add: at least 3 photos', 'submission lists exactly what is missing');

select lives_ok($$
  insert into public.property_images (property_id, storage_path, display_order) values
    ('12000000-0000-4000-a000-000000000001', '11000000-0000-4000-a000-000000000001/12000000-0000-4000-a000-000000000001/a.jpg', 0),
    ('12000000-0000-4000-a000-000000000001', '11000000-0000-4000-a000-000000000001/12000000-0000-4000-a000-000000000001/b.jpg', 1),
    ('12000000-0000-4000-a000-000000000001', '11000000-0000-4000-a000-000000000001/12000000-0000-4000-a000-000000000001/c.jpg', 2)
$$, 'host can add photos');

select lives_ok($$
  select public.reorder_property_images('12000000-0000-4000-a000-000000000001',
    array(select id from public.property_images where property_id = '12000000-0000-4000-a000-000000000001' order by display_order desc))
$$, 'host can reorder photos');

select is(public.submit_property_for_review('12000000-0000-4000-a000-000000000001'),
  'pending_review'::public.property_status, 'complete draft can be submitted');

-- Another host cannot touch it.
reset role;
set local request.jwt.claims to '{"sub":"11000000-0000-4000-a000-000000000002","role":"authenticated"}';
set local role authenticated;
select throws_ok($$
  insert into public.property_images (property_id, storage_path, display_order)
  values ('12000000-0000-4000-a000-000000000001', 'x/y/z.jpg', 9)
$$, '42501', null, 'other hosts cannot add photos to the listing');
select is((select count(*)::int from public.property_contacts where property_id = '12000000-0000-4000-a000-000000000001'), 0,
  'other hosts cannot read the contact number');

-- Admin approves; a guest enquires; the host replies.
reset role;
update public.properties set status = 'published', approved_at = now() where id = '12000000-0000-4000-a000-000000000001';

set local request.jwt.claims to '{"sub":"11000000-0000-4000-a000-000000000003","role":"authenticated"}';
set local role authenticated;
insert into public.enquiries (id, property_id, check_in, check_out, guest_count, guest_name, guest_contact)
values ('13000000-0000-4000-a000-000000000001', '12000000-0000-4000-a000-000000000001',
        current_date + 5, current_date + 7, 2, 'Gabriel Guest', '+254722000222');

reset role;
set local request.jwt.claims to '{"sub":"11000000-0000-4000-a000-000000000001","role":"authenticated"}';
set local role authenticated;
select is((select guest_contact from public.enquiries where id = '13000000-0000-4000-a000-000000000001'),
  '+254722000222', 'host sees the guest''s reply contact');
select is(public.owner_update_enquiry('13000000-0000-4000-a000-000000000001', 'available', 'Yes, it is free. Call me.'),
  'available'::public.enquiry_status, 'host can say the place is available');
select ok((select responded_at is not null from public.enquiries where id = '13000000-0000-4000-a000-000000000001'),
  'reply time is recorded');

-- Response time appears only after 5 answered enquiries.
select is((select typical_response_hours from public.get_host_summary('12000000-0000-4000-a000-000000000001')), null,
  'no response time shown with fewer than 5 replies');

reset role;
insert into public.enquiries (property_id, guest_id, check_in, check_out, guest_count, guest_name, guest_contact, status, created_at, responded_at)
select '12000000-0000-4000-a000-000000000001', '11000000-0000-4000-a000-000000000003', current_date + 20 + g, current_date + 22 + g,
  1, 'Gabriel Guest', '+254722000222', 'available', now() - interval '3 days', now() - interval '3 days' + interval '2 hours'
from generate_series(1, 5) g;
select is((select typical_response_hours from public.get_host_summary('12000000-0000-4000-a000-000000000001')), 2.0,
  'median response time is shown once there are enough replies');

select * from finish();
rollback;
