-- Initial configurable reference data (production-safe; not demo listings).
-- Admins can add, rename, reorder or deactivate rows later.

insert into public.neighbourhoods (name, slug, county, latitude, longitude, is_popular, sort_order) values
  ('Kilimani',   'kilimani',   'Nairobi', -1.290700, 36.784000, true,  10),
  ('Kileleshwa', 'kileleshwa', 'Nairobi', -1.280200, 36.781500, true,  20),
  ('Westlands',  'westlands',  'Nairobi', -1.267600, 36.810800, true,  30),
  ('Ruaka',      'ruaka',      'Kiambu',  -1.208000, 36.779300, true,  40),
  ('Roysambu',   'roysambu',   'Nairobi', -1.218400, 36.886400, true,  50),
  ('Kasarani',   'kasarani',   'Nairobi', -1.221800, 36.903800, false, 60),
  ('South B',    'south-b',    'Nairobi', -1.309800, 36.836000, true,  70),
  ('South C',    'south-c',    'Nairobi', -1.318700, 36.825400, false, 80),
  ('Embakasi',   'embakasi',   'Nairobi', -1.317500, 36.900000, false, 90),
  ('Ngara',      'ngara',      'Nairobi', -1.274200, 36.825700, false, 100)
on conflict (slug) do nothing;

insert into public.amenities (name, slug, category, icon, is_key, sort_order) values
  ('Wi-Fi',                 'wifi',              'essentials', 'wifi',             true,  10),
  ('Hot shower',            'hot-shower',        'essentials', 'shower',           true,  20),
  ('Secure parking',        'parking',           'essentials', 'local_parking',    true,  30),
  ('Backup power',          'backup-power',      'essentials', 'bolt',             true,  40),
  ('Reliable water supply', 'water-supply',      'essentials', 'water_drop',       false, 50),
  ('Fully equipped kitchen','kitchen',           'essentials', 'kitchen',          true,  60),
  ('24-hour security',      'security',          'safety',     'shield',           false, 70),
  ('CCTV',                  'cctv',              'safety',     'videocam',         false, 80),
  ('Smart TV',              'smart-tv',          'comfort',    'tv',               false, 90),
  ('DStv',                  'dstv',              'comfort',    'satellite_alt',    false, 100),
  ('Washing machine',       'washing-machine',   'comfort',    'local_laundry_service', false, 110),
  ('Workspace',             'workspace',         'comfort',    'desk',             false, 120),
  ('Balcony',               'balcony',           'comfort',    'balcony',          false, 130),
  ('Lift',                  'lift',              'building',   'elevator',         false, 140),
  ('Swimming pool',         'swimming-pool',     'building',   'pool',             false, 150),
  ('Gym',                   'gym',               'building',   'fitness_center',   false, 160),
  ('Housekeeping',          'housekeeping',      'services',   'cleaning_services',false, 170),
  ('Airport transfer',      'airport-transfer',  'services',   'airport_shuttle',  false, 180),
  ('Pet friendly',          'pet-friendly',      'policies',   'pets',             false, 190)
on conflict (slug) do nothing;
