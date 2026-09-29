-- Additive Super Admin controls for BERP.
-- Safe to run after 028. Re-asserts founders and adds suspend.

alter table public.profiles
  add column if not exists suspended boolean not null default false;

alter table public.profiles
  add column if not exists suspended_at timestamptz;

alter table public.profiles
  add column if not exists suspended_by uuid references public.profiles (id);

alter table public.profiles
  add column if not exists suspended_reason text not null default '';

-- Keep founder accounts as Super Admin (case-insensitive).
update public.profiles
set role = 'super_admin',
    suspended = false,
    suspended_at = null,
    suspended_by = null,
    suspended_reason = ''
where lower(email) in ('olamide@vmoaeros.com', 'akintoyelmd@gmail.com');

create or replace function public.berp_assign_founders()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if lower(coalesce(new.email, '')) in (
    'olamide@vmoaeros.com',
    'akintoyelmd@gmail.com'
  ) then
    new.role := 'super_admin';
    new.suspended := false;
  elsif new.role is null or btrim(new.role) = '' then
    new.role := 'staff';
  end if;
  return new;
end $$;

create or replace function public.berp_guard_suspend()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  actor text;
begin
  if new.suspended is not distinct from old.suspended
     and new.suspended_reason is not distinct from old.suspended_reason then
    return new;
  end if;
  if auth.uid() is null then
    return new;
  end if;
  actor := public.berp_role();
  if actor not in ('admin', 'super_admin', 'hr_manager') then
    raise exception 'Not allowed to suspend staff';
  end if;
  -- Nobody may suspend a super admin except another super admin.
  if old.role = 'super_admin' and actor is distinct from 'super_admin' then
    raise exception 'Only a super admin can suspend a super admin';
  end if;
  if lower(coalesce(old.email, '')) in (
    'olamide@vmoaeros.com',
    'akintoyelmd@gmail.com'
  ) then
    raise exception 'Founder accounts cannot be suspended';
  end if;
  if new.suspended then
    new.suspended_at := coalesce(new.suspended_at, now());
    new.suspended_by := auth.uid();
  else
    new.suspended_at := null;
    new.suspended_by := null;
    new.suspended_reason := '';
  end if;
  return new;
end $$;

drop trigger if exists berp_guard_suspend on public.profiles;
create trigger berp_guard_suspend
  before update on public.profiles
  for each row
  execute function public.berp_guard_suspend();

create or replace function public.berp_is_suspended()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select suspended from public.profiles where id = auth.uid()),
    false
  )
$$;

grant execute on function public.berp_is_suspended() to authenticated;

-- Suspended staff cannot clock or create leave/updates.
drop policy if exists "clock insert own" on public.clock_sessions;
create policy "clock insert own"
  on public.clock_sessions for insert
  to authenticated
  with check (user_id = auth.uid() and not public.berp_is_suspended());

drop policy if exists "leave insert own" on public.leave_requests;
create policy "leave insert own"
  on public.leave_requests for insert
  to authenticated
  with check (user_id = auth.uid() and not public.berp_is_suspended());

notify pgrst, 'reload schema';
