-- Property photos bucket.
-- Public read (published listings need cacheable CDN URLs; object names are
-- random UUIDs). Writes are restricted to the owner of the listing, under the
-- path convention: {owner_id}/{property_id}/{uuid}.jpg
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('property-images', 'property-images', true, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Validates the path shape before casting so malformed names fail cleanly.
create or replace function public.storage_path_property_editable(p_name text)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_parts text[] := storage.foldername(p_name);
begin
  if cardinality(v_parts) <> 2
     or v_parts[1] <> auth.uid()::text
     or v_parts[2] !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
    return false;
  end if;
  return public.can_edit_property(v_parts[2]::uuid);
end;
$$;

grant execute on function public.storage_path_property_editable(text) to authenticated;

create policy "property-images: owner uploads"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'property-images' and public.storage_path_property_editable(name));

create policy "property-images: owner reads own objects"
  on storage.objects for select to authenticated
  using (bucket_id = 'property-images' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "property-images: owner updates"
  on storage.objects for update to authenticated
  using (bucket_id = 'property-images' and public.storage_path_property_editable(name))
  with check (bucket_id = 'property-images' and public.storage_path_property_editable(name));

create policy "property-images: owner deletes"
  on storage.objects for delete to authenticated
  using (bucket_id = 'property-images' and public.storage_path_property_editable(name));
