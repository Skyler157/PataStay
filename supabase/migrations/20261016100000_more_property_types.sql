-- More property types (penthouses and villas) and the upmarket Nairobi
-- neighbourhoods where most of them are. "house" is labelled "Private house"
-- in the apps. ADD VALUE cannot be used in the same transaction, so the new
-- values are only referenced by later migrations / seed data.
alter type public.property_type add value if not exists 'penthouse';
alter type public.property_type add value if not exists 'villa';

insert into public.neighbourhoods (name, slug, county, latitude, longitude, is_popular, sort_order) values
  ('Lavington', 'lavington', 'Nairobi', -1.276500, 36.769500, false, 110),
  ('Karen',     'karen',     'Nairobi', -1.319200, 36.707300, false, 120),
  ('Runda',     'runda',     'Nairobi', -1.218700, 36.815400, false, 130)
on conflict (slug) do nothing;
