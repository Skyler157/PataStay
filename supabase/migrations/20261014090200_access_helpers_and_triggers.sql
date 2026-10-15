-- Access helpers and integrity triggers.
-- All SECURITY DEFINER functions pin search_path to '' and fully qualify names.

-- ---------------------------------------------------------------------------
-- Role helpers (used inside RLS policies; wrap in a subselect in policies so
-- Postgres evaluates them once per statement).
-- ---------------------------------------------------------------------------
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin' and account_status = 'active'
  );
$$;

create or replace function public.is_active_user()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and account_status = 'active'
  );
$$;

create or replace function public.is_active_owner()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role in ('owner', 'admin') and account_status = 'active'
  );
$$;

-- True when the current user owns the property (any status).
create or replace function public.owns_property(p_property_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.properties
    where id = p_property_id and owner_id = auth.uid()
  );
$$;

-- True when the current user owns the property and may still edit it.
create or replace function public.can_edit_property(p_property_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.properties p
    join public.profiles pr on pr.id = p.owner_id
    where p.id = p_property_id
      and p.owner_id = auth.uid()
      and pr.account_status = 'active'
      and p.status not in ('suspended', 'archived')
  );
$$;

-- ---------------------------------------------------------------------------
-- New auth users get a profile. The role is NEVER taken from client metadata
-- except the harmless choice between guest and owner.
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, email, role)
  values (
    new.id,
    left(coalesce(new.raw_user_meta_data ->> 'full_name', ''), 120),
    new.email,
    case when new.raw_user_meta_data ->> 'intended_role' = 'owner'
      then 'owner'::public.user_role
      else 'guest'::public.user_role
    end
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create or replace function public.handle_user_email_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.profiles set email = new.email where id = new.id;
  return new;
end;
$$;

create trigger on_auth_user_email_changed
  after update of email on auth.users
  for each row
  when (old.email is distinct from new.email)
  execute function public.handle_user_email_change();

-- ---------------------------------------------------------------------------
-- Property status audit trail. RPCs pass a reason through the transaction-
-- local setting patastay.status_reason.
-- ---------------------------------------------------------------------------
create or replace function public.log_property_status_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' or old.status is distinct from new.status then
    insert into public.property_status_history (property_id, from_status, to_status, changed_by, reason)
    values (
      new.id,
      case when tg_op = 'UPDATE' then old.status end,
      new.status,
      auth.uid(),
      nullif(current_setting('patastay.status_reason', true), '')
    );
  end if;
  return new;
end;
$$;

create trigger properties_log_status
  after insert or update of status on public.properties
  for each row execute function public.log_property_status_change();

-- Changing the contact number of a live listing is a classic takeover/scam
-- pattern, so it sends the listing back for review.
create or replace function public.recheck_property_on_contact_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (old.phone is distinct from new.phone or old.whatsapp_phone is distinct from new.whatsapp_phone)
     and not public.is_admin() then
    perform set_config('patastay.status_reason', 'Contact number changed; re-review required', true);
    update public.properties
      set status = 'pending_review', submitted_at = now()
      where id = new.property_id and status in ('published', 'paused');
  end if;
  return new;
end;
$$;

create trigger property_contacts_recheck
  after update on public.property_contacts
  for each row execute function public.recheck_property_on_contact_change();

-- ---------------------------------------------------------------------------
-- Enquiry validation (server side). Clients cannot choose guest_id or status.
-- ---------------------------------------------------------------------------
create or replace function public.validate_enquiry()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_property public.properties;
  v_recent integer;
begin
  if auth.uid() is null then
    raise exception 'You must be signed in to send an enquiry' using errcode = '42501';
  end if;

  if not public.is_active_user() then
    raise exception 'Your account is not active' using errcode = '42501';
  end if;

  new.guest_id := auth.uid();
  new.status := 'new';
  new.guest_name := trim(new.guest_name);
  new.guest_contact := trim(new.guest_contact);

  select * into v_property from public.properties where id = new.property_id;

  if v_property.id is null or v_property.status <> 'published' then
    raise exception 'This property is not accepting enquiries' using errcode = 'P0001';
  end if;

  if v_property.owner_id = auth.uid() then
    raise exception 'You cannot enquire about your own property' using errcode = 'P0001';
  end if;

  if new.check_in < (now() at time zone 'Africa/Nairobi')::date then
    raise exception 'Check-in date cannot be in the past' using errcode = 'P0001';
  end if;

  if new.check_in > (now() at time zone 'Africa/Nairobi')::date + 365 then
    raise exception 'Check-in date must be within the next 12 months' using errcode = 'P0001';
  end if;

  if new.guest_count > v_property.maximum_guests then
    raise exception 'This property hosts at most % guests', v_property.maximum_guests using errcode = 'P0001';
  end if;

  if (new.check_out - new.check_in) < v_property.minimum_nights then
    raise exception 'This property requires a minimum stay of % nights', v_property.minimum_nights using errcode = 'P0001';
  end if;

  select count(*) into v_recent
    from public.enquiries
    where guest_id = auth.uid() and created_at > now() - interval '24 hours';

  if v_recent >= 15 then
    raise exception 'Too many enquiries today. Please try again tomorrow.' using errcode = 'P0001';
  end if;

  return new;
end;
$$;

create trigger enquiries_validate
  before insert on public.enquiries
  for each row execute function public.validate_enquiry();

create or replace function public.record_enquiry_event()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.listing_events (property_id, event_type, user_id)
  values (new.property_id, 'enquiry_submitted', new.guest_id);
  return new;
end;
$$;

create trigger enquiries_record_event
  after insert on public.enquiries
  for each row execute function public.record_enquiry_event();

-- Reports: reporter is always the caller.
create or replace function public.prepare_property_report()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'You must be signed in to report a listing' using errcode = '42501';
  end if;
  new.reporter_id := auth.uid();
  new.status := 'open';
  new.resolution_note := null;
  new.resolved_by := null;
  new.resolved_at := null;
  return new;
end;
$$;

create trigger property_reports_prepare
  before insert on public.property_reports
  for each row execute function public.prepare_property_report();

-- Favourites: count as a listing event (useful demand signal for owners).
create or replace function public.record_favourite_event()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.listing_events (property_id, event_type, user_id)
  values (new.property_id, 'favourite_added', new.user_id);
  return new;
end;
$$;

create trigger favourites_record_event
  after insert on public.favourites
  for each row execute function public.record_favourite_event();
