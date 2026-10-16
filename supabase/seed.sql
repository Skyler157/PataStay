-- DEVELOPMENT SEED DATA ONLY. Applied by `supabase db reset` on a LOCAL stack.
-- Never run against production. All listings are flagged is_seed = true and
-- use 'seed/' image paths, which the apps render as labelled placeholders.
--
-- Local test accounts (password for all: PataStay#Dev2026):
--   admin@patastay.local  (admin)
--   owner@patastay.local  (owner)
--   guest@patastay.local  (guest)

do $$
declare
  v_users jsonb := '[
    {"id":"00000000-0000-4000-a000-000000000001","email":"admin@patastay.local","name":"Amina Admin"},
    {"id":"00000000-0000-4000-a000-000000000002","email":"owner@patastay.local","name":"Otieno Owner"},
    {"id":"00000000-0000-4000-a000-000000000003","email":"guest@patastay.local","name":"Wanjiku Guest"}
  ]';
  u jsonb;
begin
  for u in select * from jsonb_array_elements(v_users) loop
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, recovery_token, email_change_token_new, email_change
    ) values (
      '00000000-0000-0000-0000-000000000000', (u->>'id')::uuid, 'authenticated', 'authenticated',
      u->>'email', extensions.crypt('PataStay#Dev2026', extensions.gen_salt('bf')), now(),
      '{"provider":"email","providers":["email"]}', jsonb_build_object('full_name', u->>'name'),
      now(), now(), '', '', '', ''
    );
    insert into auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
    values (
      gen_random_uuid(), (u->>'id')::uuid, u->>'id',
      jsonb_build_object('sub', u->>'id', 'email', u->>'email', 'email_verified', true),
      'email', now(), now(), now()
    );
  end loop;
end $$;

update public.profiles set role = 'admin', phone = '+254700000001' where id = '00000000-0000-4000-a000-000000000001';
update public.profiles set role = 'owner', phone = '+254700000002' where id = '00000000-0000-4000-a000-000000000002';
update public.profiles set phone = '+254700000003' where id = '00000000-0000-4000-a000-000000000003';

-- Sample listings (owned by the seed owner).
with seed(id, title, ptype, hood, rate, cleaning, deposit, beds, baths, guests, featured, verified, status, descr) as (
  values
  ('10000000-0000-4000-a000-000000000001'::uuid, 'Bright studio near Yaya Centre', 'studio', 'kilimani', 3500, 500, 0, 0, 1.0, 2, true, true, 'published',
   'A compact, sunny studio a short walk from Yaya Centre with fast Wi-Fi, hot shower and a small kitchenette. Ideal for solo travellers and couples.'),
  ('10000000-0000-4000-a000-000000000002', 'Furnished 1-bedroom in Kileleshwa', 'one_bedroom', 'kileleshwa', 5500, 1000, 5000, 1, 1.0, 3, true, false, 'published',
   'Quiet one-bedroom apartment with a balcony, backup generator and secure parking. Close to Othaya Road shops and public transport.'),
  ('10000000-0000-4000-a000-000000000003', 'Modern apartment off Waiyaki Way', 'furnished_apartment', 'westlands', 7800, 1500, 10000, 2, 2.0, 4, false, true, 'published',
   'Two-bedroom furnished apartment with lift access, gym and pool. Convenient for business travel to Westlands and the CBD.'),
  ('10000000-0000-4000-a000-000000000004', 'Affordable bedsitter in Roysambu', 'bedsitter', 'roysambu', 1800, 0, 0, 0, 1.0, 1, false, false, 'published',
   'Simple, clean bedsitter near Thika Road Mall. Hot shower, reliable water and 24-hour security. Good value for short work trips.'),
  ('10000000-0000-4000-a000-000000000005', 'Family guest house in South B', 'guest_house', 'south-b', 4200, 500, 0, 3, 2.0, 6, false, false, 'published',
   'Spacious guest house with a shared kitchen and garden, 20 minutes from JKIA depending on traffic. Airport transfers can be arranged.'),
  ('10000000-0000-4000-a000-000000000006', 'Cosy 1-bedroom in Ruaka', 'one_bedroom', 'ruaka', 3000, 500, 3000, 1, 1.0, 2, false, false, 'pending_review',
   'Cosy one-bedroom with a balcony and fast Wi-Fi, in a quiet compound with a borehole. Close to Two Rivers Mall and Limuru Road.')
)
insert into public.properties (
  id, owner_id, title, description, property_type, neighbourhood_id, address_or_area_description,
  nightly_rate, cleaning_fee, refundable_deposit, bedrooms, bathrooms, maximum_guests,
  check_in_time, check_out_time, check_in_information, check_out_information, house_rules,
  status, is_featured, verified_at, availability_confirmed_at, submitted_at, approved_at, published_at, is_seed
)
select s.id, '00000000-0000-4000-a000-000000000002', s.title, s.descr, s.ptype::public.property_type, n.id,
  'Sample area description, ' || n.name,
  s.rate, s.cleaning, s.deposit, s.beds, s.baths, s.guests,
  '14:00', '10:00', 'Self check-in with a caretaker on site.', 'Leave keys with the caretaker.',
  'No smoking indoors. No parties. Quiet hours 10pm to 7am.',
  s.status::public.property_status, s.featured,
  case when s.verified then now() - interval '5 days' end,
  now() - (random() * interval '6 days'),
  now() - interval '10 days',
  case when s.status = 'published' then now() - interval '9 days' end,
  case when s.status = 'published' then now() - interval '9 days' end,
  true
from seed s join public.neighbourhoods n on n.slug = s.hood;

insert into public.property_contacts (property_id, phone, whatsapp_phone)
select id, '+254700000002', '+254700000002' from public.properties where is_seed;

insert into public.property_images (property_id, storage_path, display_order, caption)
select p.id, 'seed/' || p.id || '/placeholder-' || g || '.jpg', g - 1, null
from public.properties p cross join generate_series(1, 3) g
where p.is_seed;

insert into public.property_amenities (property_id, amenity_id)
select p.id, a.id from public.properties p
join public.amenities a on a.slug in ('wifi', 'hot-shower', 'security', 'water-supply')
where p.is_seed;

insert into public.property_amenities (property_id, amenity_id)
select p.id, a.id from public.properties p
join public.amenities a on a.slug in ('parking', 'backup-power', 'kitchen')
where p.is_seed and p.bedrooms >= 1;

-- Exact sample pins (private). Public coordinates are derived ~300 m away.
insert into public.property_locations (property_id, latitude, longitude) values
  ('10000000-0000-4000-a000-000000000001', -1.292300, 36.787600),
  ('10000000-0000-4000-a000-000000000002', -1.278900, 36.783100),
  ('10000000-0000-4000-a000-000000000003', -1.263400, 36.802900),
  ('10000000-0000-4000-a000-000000000004', -1.217800, 36.889600),
  ('10000000-0000-4000-a000-000000000005', -1.311200, 36.838900),
  ('10000000-0000-4000-a000-000000000006', -1.209600, 36.776500);

-- Sample listings for the larger property types (PS-1007 .. PS-1011).
with seed(id, title, ptype, hood, rate, cleaning, deposit, beds, baths, guests, verified, descr) as (
  values
  ('10000000-0000-4000-a000-000000000007'::uuid, 'Spacious 2-bedroom in Kileleshwa', 'two_bedroom', 'kileleshwa', 6500, 1000, 5000, 2, 2.0, 4, true,
   'Bright two-bedroom apartment with a master en-suite, open-plan kitchen, backup generator and two parking slots. Walking distance to Kileleshwa shops.'),
  ('10000000-0000-4000-a000-000000000008', 'Family 3-bedroom in Lavington', 'three_bedroom_plus', 'lavington', 9500, 1500, 10000, 3, 3.0, 6, false,
   'Three-bedroom apartment in a quiet gated compound with a children''s play area, borehole water and 24-hour security. Close to Lavington Mall.'),
  ('10000000-0000-4000-a000-000000000009', 'Westlands penthouse with city views', 'penthouse', 'westlands', 18000, 2500, 20000, 3, 3.5, 6, true,
   'Top-floor penthouse with a wraparound terrace, floor-to-ceiling windows and views over the Westlands skyline. Gym and pool in the building.'),
  ('10000000-0000-4000-a000-000000000010', 'Garden villa in Karen', 'villa', 'karen', 25000, 3000, 30000, 4, 4.0, 8, true,
   'Four-bedroom villa on half an acre of garden with a pool, staff quarters and a fireplace. Ten minutes from the Giraffe Centre.'),
  ('10000000-0000-4000-a000-000000000011', 'Private house with garden in Runda', 'house', 'runda', 15000, 2000, 15000, 3, 3.0, 6, false,
   'Standalone three-bedroom house with a private garden, parking for three cars and a quiet, leafy street. Close to the UN offices in Gigiri.')
)
insert into public.properties (
  id, owner_id, title, description, property_type, neighbourhood_id, address_or_area_description,
  nightly_rate, cleaning_fee, refundable_deposit, bedrooms, bathrooms, maximum_guests,
  check_in_time, check_out_time, check_in_information, check_out_information, house_rules,
  status, is_featured, verified_at, availability_confirmed_at, submitted_at, approved_at, published_at, is_seed
)
select s.id, '00000000-0000-4000-a000-000000000002', s.title, s.descr, s.ptype::public.property_type, n.id,
  'Sample area description, ' || n.name,
  s.rate, s.cleaning, s.deposit, s.beds, s.baths, s.guests,
  '14:00', '10:00', 'Meet the caretaker at the gate.', 'Leave keys with the caretaker.',
  'No smoking indoors. No parties. Quiet hours 10pm to 7am.',
  'published', false,
  case when s.verified then now() - interval '7 days' end,
  now() - interval '1 day', now() - interval '8 days', now() - interval '7 days', now() - interval '7 days', true
from seed s join public.neighbourhoods n on n.slug = s.hood;

insert into public.property_contacts (property_id, phone, whatsapp_phone)
select id, '+254700000002', '+254700000002' from public.properties
where is_seed and id::text >= '10000000-0000-4000-a000-000000000007';

insert into public.property_images (property_id, storage_path, display_order, caption)
select p.id, 'seed/' || p.id || '/placeholder-' || g || '.jpg', g - 1, null
from public.properties p cross join generate_series(1, 3) g
where p.is_seed and p.id::text >= '10000000-0000-4000-a000-000000000007';

insert into public.property_amenities (property_id, amenity_id)
select p.id, a.id from public.properties p
join public.amenities a on a.slug in ('wifi', 'hot-shower', 'security', 'water-supply', 'parking', 'backup-power', 'kitchen', 'smart-tv')
where p.is_seed and p.id::text >= '10000000-0000-4000-a000-000000000007';

insert into public.property_amenities (property_id, amenity_id)
select p.id, a.id from public.properties p
join public.amenities a on a.slug in ('swimming-pool', 'gym', 'balcony', 'lift')
where p.id = '10000000-0000-4000-a000-000000000009';

insert into public.property_amenities (property_id, amenity_id)
select p.id, a.id from public.properties p
join public.amenities a on a.slug in ('swimming-pool', 'housekeeping', 'pet-friendly')
where p.id = '10000000-0000-4000-a000-000000000010';

insert into public.property_locations (property_id, latitude, longitude) values
  ('10000000-0000-4000-a000-000000000007', -1.281200, 36.785900),
  ('10000000-0000-4000-a000-000000000008', -1.278100, 36.767300),
  ('10000000-0000-4000-a000-000000000009', -1.265900, 36.806200),
  ('10000000-0000-4000-a000-000000000010', -1.326100, 36.711800),
  ('10000000-0000-4000-a000-000000000011', -1.215300, 36.818900);

-- Realistic area descriptions (public, approximate - never a street address).
update public.properties p set address_or_area_description = v.area
from (values
  ('10000000-0000-4000-a000-000000000001'::uuid, 'Near Yaya Centre, off Argwings Kodhek Road'),
  ('10000000-0000-4000-a000-000000000002', 'Off Othaya Road, Kileleshwa'),
  ('10000000-0000-4000-a000-000000000003', 'Off Waiyaki Way, near Westgate'),
  ('10000000-0000-4000-a000-000000000004', 'Near Thika Road Mall (TRM), Roysambu'),
  ('10000000-0000-4000-a000-000000000005', 'Off Mombasa Road, South B'),
  ('10000000-0000-4000-a000-000000000006', 'Off Limuru Road, near Two Rivers Mall'),
  ('10000000-0000-4000-a000-000000000007', 'Near Kileleshwa shopping centre'),
  ('10000000-0000-4000-a000-000000000008', 'Off James Gichuru Road, Lavington'),
  ('10000000-0000-4000-a000-000000000009', 'Off Woodvale Grove, Westlands'),
  ('10000000-0000-4000-a000-000000000010', 'Near the Giraffe Centre, Karen'),
  ('10000000-0000-4000-a000-000000000011', 'Near the UN offices in Gigiri, Runda')
) as v(id, area)
where p.id = v.id;
