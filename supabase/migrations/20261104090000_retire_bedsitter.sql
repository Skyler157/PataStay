-- "Bedsitter" is no longer offered as a property type. Postgres cannot drop an
-- enum value, so existing bedsitter listings become studios (the closest type)
-- and a check constraint stops new ones.
update public.properties set property_type = 'studio' where property_type = 'bedsitter';

alter table public.properties
  add constraint properties_no_bedsitter check (property_type is distinct from 'bedsitter');
