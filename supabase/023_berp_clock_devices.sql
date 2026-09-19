-- BERP clock device fingerprinting (phone id, public IP, device type).
-- Run after 017_berp_lagos_clock.sql:
-- https://supabase.com/dashboard/project/vfrgawklszvhddrvjjxj/sql/new

alter table public.clock_sessions
  add column if not exists device_id text,
  add column if not exists device_label text,
  add column if not exists device_model text,
  add column if not exists device_os text,
  add column if not exists public_ip text;

create index if not exists idx_clock_sessions_user_device
  on public.clock_sessions (app_id, user_id, device_id, clock_in desc);

create index if not exists idx_clock_sessions_device_week
  on public.clock_sessions (app_id, user_id, clock_in desc)
  where device_id is not null;

-- Registry of devices seen per staff member (useful for HR reviews).
create table if not exists public.clock_devices (
  id uuid primary key default gen_random_uuid(),
  app_id text not null references public.apps (id),
  user_id uuid not null references public.profiles (id) on delete cascade,
  device_id text not null,
  device_label text not null default '',
  device_model text not null default '',
  device_os text not null default '',
  last_public_ip text,
  first_seen_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  unique (app_id, user_id, device_id)
);

create index if not exists idx_clock_devices_user
  on public.clock_devices (app_id, user_id, last_seen_at desc);

alter table public.clock_devices enable row level security;

drop policy if exists "clock devices read own or hr" on public.clock_devices;
create policy "clock devices read own or hr"
  on public.clock_devices for select
  to authenticated
  using (
    user_id = auth.uid()
    or public.current_user_role() in ('super_admin', 'hr_manager')
  );

drop policy if exists "clock devices upsert own" on public.clock_devices;
create policy "clock devices upsert own"
  on public.clock_devices for insert
  to authenticated
  with check (user_id = auth.uid() and app_id = 'berp');

drop policy if exists "clock devices update own" on public.clock_devices;
create policy "clock devices update own"
  on public.clock_devices for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "clock devices manage hr" on public.clock_devices;
create policy "clock devices manage hr"
  on public.clock_devices for all
  to authenticated
  using (public.current_user_role() in ('super_admin', 'hr_manager'));

grant select, insert, update, delete on public.clock_devices
  to authenticated, service_role;

notify pgrst, 'reload schema';

select column_name
from information_schema.columns
where table_schema = 'public'
  and table_name = 'clock_sessions'
  and column_name in (
    'device_id',
    'device_label',
    'device_model',
    'device_os',
    'public_ip'
  )
order by column_name;
