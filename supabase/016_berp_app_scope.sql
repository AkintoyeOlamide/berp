-- BERP + BHR share the same Supabase project.
-- user_id = who (auth.users / profiles)
-- app_id  = which product (berp)
--
-- Run this in the BHR project SQL editor:
-- https://supabase.com/dashboard/project/vfrgawklszvhddrvjjxj/sql/new
-- Success = green "Success" AND a results grid with 4 table names.
-- A red Error means nothing was created (the whole script rolled back).

create table if not exists public.apps (
  id text primary key,
  name text not null,
  created_at timestamptz not null default now()
);

insert into public.apps (id, name)
values ('berp', 'BERP')
on conflict (id) do nothing;

create table if not exists public.clock_sessions (
  id uuid primary key default gen_random_uuid(),
  app_id text not null references public.apps (id),
  user_id uuid not null references public.profiles (id) on delete cascade,
  clock_in timestamptz not null,
  clock_out timestamptz,
  site_id text,
  site_name text,
  created_at timestamptz not null default now()
);

create table if not exists public.leave_requests (
  id uuid primary key default gen_random_uuid(),
  app_id text not null references public.apps (id),
  user_id uuid not null references public.profiles (id) on delete cascade,
  kind text not null default 'annual'
    check (kind in ('annual', 'sick', 'unpaid', 'compassionate')),
  start_date date not null,
  end_date date not null,
  note text not null default '',
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'declined')),
  created_at timestamptz not null default now()
);

create table if not exists public.staff_updates (
  id uuid primary key default gen_random_uuid(),
  app_id text not null references public.apps (id),
  user_id uuid not null references public.profiles (id) on delete cascade,
  author_name text not null default '',
  author_role text not null default '',
  title text not null,
  body text not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_clock_sessions_app_user
  on public.clock_sessions (app_id, user_id, clock_in desc);
create index if not exists idx_leave_requests_app_user
  on public.leave_requests (app_id, user_id, start_date desc);
create index if not exists idx_staff_updates_app
  on public.staff_updates (app_id, created_at desc);

alter table public.apps enable row level security;
alter table public.clock_sessions enable row level security;
alter table public.leave_requests enable row level security;
alter table public.staff_updates enable row level security;

drop policy if exists "apps readable" on public.apps;
create policy "apps readable"
  on public.apps for select
  to authenticated
  using (true);

-- Clock
drop policy if exists "clock read own or hr" on public.clock_sessions;
create policy "clock read own or hr"
  on public.clock_sessions for select
  to authenticated
  using (
    user_id = auth.uid()
    or public.current_user_role() in ('super_admin', 'hr_manager')
  );

drop policy if exists "clock insert own" on public.clock_sessions;
create policy "clock insert own"
  on public.clock_sessions for insert
  to authenticated
  with check (user_id = auth.uid());

drop policy if exists "clock update own" on public.clock_sessions;
create policy "clock update own"
  on public.clock_sessions for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "clock manage hr" on public.clock_sessions;
create policy "clock manage hr"
  on public.clock_sessions for all
  to authenticated
  using (public.current_user_role() in ('super_admin', 'hr_manager'));

-- Leave
drop policy if exists "leave read own or hr" on public.leave_requests;
create policy "leave read own or hr"
  on public.leave_requests for select
  to authenticated
  using (
    user_id = auth.uid()
    or public.current_user_role() in ('super_admin', 'hr_manager')
  );

drop policy if exists "leave insert own" on public.leave_requests;
create policy "leave insert own"
  on public.leave_requests for insert
  to authenticated
  with check (user_id = auth.uid());

drop policy if exists "leave update hr" on public.leave_requests;
create policy "leave update hr"
  on public.leave_requests for update
  to authenticated
  using (public.current_user_role() in ('super_admin', 'hr_manager'));

-- Updates / news: everyone in BERP can read; anyone can post; HR sees all apps
drop policy if exists "updates read app or hr" on public.staff_updates;
create policy "updates read app or hr"
  on public.staff_updates for select
  to authenticated
  using (
    app_id = 'berp'
    or public.current_user_role() in ('super_admin', 'hr_manager')
  );

drop policy if exists "updates insert own" on public.staff_updates;
create policy "updates insert own"
  on public.staff_updates for insert
  to authenticated
  with check (user_id = auth.uid());

drop policy if exists "updates manage hr" on public.staff_updates;
create policy "updates manage hr"
  on public.staff_updates for all
  to authenticated
  using (public.current_user_role() in ('super_admin', 'hr_manager'));

grant select on public.apps to authenticated, service_role;
grant select, insert, update on public.clock_sessions to authenticated, service_role;
grant select, insert, update on public.leave_requests to authenticated, service_role;
grant select, insert, update, delete on public.staff_updates to authenticated, service_role;

notify pgrst, 'reload schema';

select table_name
from information_schema.tables
where table_schema = 'public'
  and table_name in ('apps', 'clock_sessions', 'leave_requests', 'staff_updates')
order by table_name;
