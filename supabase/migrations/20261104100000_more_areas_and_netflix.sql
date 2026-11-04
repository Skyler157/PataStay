-- More areas across Nairobi, its commuter towns and the main holiday and
-- business towns, plus a Netflix amenity. The apps group areas by city, and
-- the coordinates only centre the map when a host picks an area (admins can
-- adjust them in Areas & amenities).

insert into public.neighbourhoods (name, slug, city, county, latitude, longitude, is_popular, sort_order) values
  -- Nairobi
  ('Nairobi CBD',       'nairobi-cbd',      'Nairobi',  'Nairobi',     -1.286400, 36.825000, true,  200),
  ('Upper Hill',        'upper-hill',       'Nairobi',  'Nairobi',     -1.299000, 36.815000, false, 205),
  ('Parklands',         'parklands',        'Nairobi',  'Nairobi',     -1.263000, 36.817000, false, 210),
  ('Riverside',         'riverside',        'Nairobi',  'Nairobi',     -1.270000, 36.800000, false, 215),
  ('Spring Valley',     'spring-valley',    'Nairobi',  'Nairobi',     -1.244000, 36.798000, false, 220),
  ('Hurlingham',        'hurlingham',       'Nairobi',  'Nairobi',     -1.296000, 36.790000, false, 225),
  ('Gigiri',            'gigiri',           'Nairobi',  'Nairobi',     -1.233000, 36.805000, false, 230),
  ('Muthaiga',          'muthaiga',         'Nairobi',  'Nairobi',     -1.247000, 36.835000, false, 235),
  ('Loresho',           'loresho',          'Nairobi',  'Nairobi',     -1.256000, 36.755000, false, 240),
  ('Kitisuru',          'kitisuru',         'Nairobi',  'Nairobi',     -1.235000, 36.770000, false, 245),
  ('Ridgeways',         'ridgeways',        'Nairobi',  'Nairobi',     -1.225000, 36.839000, false, 250),
  ('Garden Estate',     'garden-estate',    'Nairobi',  'Nairobi',     -1.229000, 36.851000, false, 255),
  ('Lang''ata',         'langata',          'Nairobi',  'Nairobi',     -1.350000, 36.760000, false, 260),
  ('Madaraka',          'madaraka',         'Nairobi',  'Nairobi',     -1.305000, 36.821000, false, 265),
  ('Eastleigh',         'eastleigh',        'Nairobi',  'Nairobi',     -1.274000, 36.851000, false, 270),
  ('Buruburu',          'buruburu',         'Nairobi',  'Nairobi',     -1.286000, 36.875000, false, 275),
  ('Donholm',           'donholm',          'Nairobi',  'Nairobi',     -1.296000, 36.890000, false, 280),
  ('Imara Daima',       'imara-daima',      'Nairobi',  'Nairobi',     -1.328000, 36.886000, false, 285),
  ('Utawala',           'utawala',          'Nairobi',  'Nairobi',     -1.290000, 36.960000, false, 290),
  ('Kahawa Sukari',     'kahawa-sukari',    'Nairobi',  'Kiambu',      -1.195000, 36.933000, false, 295),
  ('Ruiru',             'ruiru',            'Nairobi',  'Kiambu',      -1.148000, 36.960000, false, 300),
  ('Juja',              'juja',             'Nairobi',  'Kiambu',      -1.103000, 37.013000, false, 305),
  ('Syokimau',          'syokimau',         'Nairobi',  'Machakos',    -1.360000, 36.938000, false, 310),
  ('Mlolongo',          'mlolongo',         'Nairobi',  'Machakos',    -1.390000, 36.945000, false, 315),
  ('Athi River',        'athi-river',       'Nairobi',  'Machakos',    -1.456000, 36.978000, false, 320),
  ('Kitengela',         'kitengela',        'Nairobi',  'Kajiado',     -1.474000, 36.960000, false, 325),
  ('Ongata Rongai',     'ongata-rongai',    'Nairobi',  'Kajiado',     -1.396000, 36.760000, false, 330),
  ('Ngong',             'ngong',            'Nairobi',  'Kajiado',     -1.360000, 36.670000, false, 335),
  -- Coast
  ('Nyali',             'nyali',            'Mombasa',  'Mombasa',     -4.028000, 39.712000, true,  400),
  ('Bamburi',           'bamburi',          'Mombasa',  'Mombasa',     -3.997000, 39.727000, false, 405),
  ('Shanzu',            'shanzu',           'Mombasa',  'Mombasa',     -3.953000, 39.751000, false, 410),
  ('Mombasa Old Town',  'mombasa-old-town', 'Mombasa',  'Mombasa',     -4.062000, 39.676000, false, 415),
  ('Mtwapa',            'mtwapa',           'Mombasa',  'Kilifi',      -3.942000, 39.745000, false, 420),
  ('Diani',             'diani',            'Diani',    'Kwale',       -4.280000, 39.580000, true,  430),
  ('Kilifi',            'kilifi',           'Kilifi',   'Kilifi',      -3.630000, 39.850000, false, 440),
  ('Watamu',            'watamu',           'Watamu',   'Kilifi',      -3.354000, 40.024000, false, 450),
  ('Malindi',           'malindi',          'Malindi',  'Kilifi',      -3.219000, 40.117000, false, 460),
  ('Lamu Town',         'lamu-town',        'Lamu',     'Lamu',        -2.270000, 40.902000, false, 470),
  ('Shela',             'shela',            'Lamu',     'Lamu',        -2.293000, 40.913000, false, 475),
  -- Rift Valley, Central and Western
  ('Naivasha',          'naivasha',         'Naivasha', 'Nakuru',      -0.717000, 36.431000, true,  500),
  ('Nakuru Town',       'nakuru-town',      'Nakuru',   'Nakuru',      -0.303000, 36.080000, false, 510),
  ('Maasai Mara',       'maasai-mara',      'Maasai Mara', 'Narok',    -1.490000, 35.144000, false, 520),
  ('Nanyuki',           'nanyuki',          'Nanyuki',  'Laikipia',     0.016700, 37.074000, false, 530),
  ('Nyeri Town',        'nyeri-town',       'Nyeri',    'Nyeri',       -0.421000, 36.948000, false, 540),
  ('Thika Town',        'thika-town',       'Thika',    'Kiambu',      -1.033300, 37.069300, false, 550),
  ('Machakos Town',     'machakos-town',    'Machakos', 'Machakos',    -1.517700, 37.263400, false, 560),
  ('Embu Town',         'embu-town',        'Embu',     'Embu',        -0.538000, 37.458000, false, 570),
  ('Meru Town',         'meru-town',        'Meru',     'Meru',         0.047000, 37.649000, false, 580),
  ('Eldoret',           'eldoret',          'Eldoret',  'Uasin Gishu',  0.514300, 35.269800, false, 590),
  ('Kisumu CBD',        'kisumu-cbd',       'Kisumu',   'Kisumu',      -0.091700, 34.768000, false, 600),
  ('Milimani, Kisumu',  'milimani-kisumu',  'Kisumu',   'Kisumu',      -0.102000, 34.756000, false, 605),
  ('Kakamega',          'kakamega',         'Kakamega', 'Kakamega',     0.282700, 34.751900, false, 610),
  ('Kisii',             'kisii',            'Kisii',    'Kisii',       -0.677000, 34.780000, false, 620)
on conflict (slug) do nothing;

insert into public.amenities (name, slug, category, icon, is_key, sort_order) values
  ('Netflix', 'netflix', 'comfort', 'live_tv', false, 105)
on conflict (slug) do nothing;
