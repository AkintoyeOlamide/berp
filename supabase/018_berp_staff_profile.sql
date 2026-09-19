-- Staff profile fields used by BERP.
-- department and job_title (designation) already exist on profiles.

alter table public.profiles
  add column if not exists company text,
  add column if not exists joined_year integer;

alter table public.profiles
  drop constraint if exists profiles_company_check;

alter table public.profiles
  add constraint profiles_company_check
  check (
    company is null
    or company in ('VMO Aero', 'CHL', 'VMO Agro')
  );

alter table public.profiles
  drop constraint if exists profiles_joined_year_check;

alter table public.profiles
  add constraint profiles_joined_year_check
  check (
    joined_year is null
    or (joined_year >= 1990 and joined_year <= 2100)
  );

grant select, insert, update on public.profiles to authenticated;

drop policy if exists "profiles insert own" on public.profiles;
create policy "profiles insert own"
  on public.profiles for insert
  to authenticated
  with check (id = auth.uid());

drop policy if exists "profiles update own or admin" on public.profiles;
create policy "profiles update own or admin"
  on public.profiles for update
  to authenticated
  using (
    id = auth.uid()
    or public.current_user_role() in ('super_admin', 'hr_manager')
  )
  with check (
    id = auth.uid()
    or public.current_user_role() in ('super_admin', 'hr_manager')
  );

notify pgrst, 'reload schema';

select column_name, data_type
from information_schema.columns
where table_schema = 'public'
  and table_name = 'profiles'
  and column_name in ('department', 'job_title', 'company', 'joined_year')
order by column_name;
