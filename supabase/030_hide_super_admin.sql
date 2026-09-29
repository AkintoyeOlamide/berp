-- Hide Super Admin accounts from everyone except Super Admins.
-- Admins can still promote staff to Manager/Admin, but Super Admin
-- stays a secret control account.

create or replace function public.berp_is_super_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.berp_role() = 'super_admin'
$$;

grant execute on function public.berp_is_super_admin() to authenticated;

-- Restrictive policy ANDs with other SELECT policies.
drop policy if exists "hide super admins from non super" on public.profiles;
create policy "hide super admins from non super"
  on public.profiles
  as restrictive
  for select
  to authenticated
  using (
    public.berp_is_super_admin()
    or coalesce(role, '') is distinct from 'super_admin'
  );

-- Admins must not update a Super Admin profile at all.
create or replace function public.berp_guard_role()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  actor text;
begin
  if auth.uid() is null then
    return new;
  end if;
  actor := public.berp_role();

  if new.manager_id is distinct from old.manager_id
     and actor not in ('admin', 'super_admin', 'hr_manager') then
    raise exception 'Not allowed to change manager';
  end if;

  -- Non-super actors cannot touch Super Admin rows (including suspend).
  if old.role = 'super_admin' and actor is distinct from 'super_admin' then
    raise exception 'Not allowed';
  end if;

  if new.role is not distinct from old.role then
    return new;
  end if;

  if actor = 'super_admin' then
    return new;
  end if;

  if actor in ('admin', 'hr_manager')
     and new.role is distinct from 'super_admin'
     and old.role is distinct from 'super_admin' then
    return new;
  end if;

  raise exception 'Not allowed to change this role';
end $$;

-- Keep founders as Super Admin.
update public.profiles
set role = 'super_admin',
    suspended = false
where lower(email) in ('olamide@vmoaeros.com', 'akintoyelmd@gmail.com');

notify pgrst, 'reload schema';
