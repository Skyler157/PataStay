-- Hosts may choose the id of a new draft listing (a random UUID generated in
-- the app). This lets the app prepare photo upload paths and retry a draft
-- creation safely on a poor connection. Ids are unique, so this grants no
-- access to anyone else's listing.
grant insert (id) on public.properties to authenticated;
