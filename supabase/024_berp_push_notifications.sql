-- BERP push notifications: admin-scheduled messages + clock reminder catalog.
-- Run in Supabase SQL editor after 023:
-- https://supabase.com/dashboard/project/vfrgawklszvhddrvjjxj/sql/new

create table if not exists public.berp_push_messages (
  id uuid primary key default gen_random_uuid(),
  app_id text not null references public.apps (id),
  kind text not null default 'admin'
    check (kind in ('admin', 'clock_reminder')),
  title text not null,
  body text not null,
  -- One-shot admin sends
  scheduled_at timestamptz,
  -- Recurring clock reminders (Lagos wall clock)
  recur_time time,
  recur_label text,
  status text not null default 'scheduled'
    check (status in ('scheduled', 'active', 'sent', 'cancelled')),
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  sent_at timestamptz,
  updated_at timestamptz not null default now()
);

create index if not exists idx_berp_push_messages_app_sched
  on public.berp_push_messages (app_id, scheduled_at desc);

create index if not exists idx_berp_push_messages_pending
  on public.berp_push_messages (app_id, status, scheduled_at)
  where kind = 'admin';

-- Per-device / per-user delivery log (what staff phones actually scheduled or showed)
create table if not exists public.berp_push_deliveries (
  id uuid primary key default gen_random_uuid(),
  app_id text not null references public.apps (id),
  message_id uuid references public.berp_push_messages (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  device_id text,
  status text not null default 'scheduled'
    check (status in ('scheduled', 'shown', 'tapped', 'skipped')),
  title text not null default '',
  body text not null default '',
  at timestamptz not null default now(),
  meta jsonb not null default '{}'::jsonb
);

create index if not exists idx_berp_push_deliveries_app
  on public.berp_push_deliveries (app_id, at desc);

create index if not exists idx_berp_push_deliveries_user
  on public.berp_push_deliveries (app_id, user_id, at desc);

alter table public.berp_push_messages enable row level security;
alter table public.berp_push_deliveries enable row level security;

drop policy if exists "push messages read berp" on public.berp_push_messages;
create policy "push messages read berp"
  on public.berp_push_messages for select
  to authenticated
  using (app_id = 'berp');

drop policy if exists "push messages insert hr" on public.berp_push_messages;
create policy "push messages insert hr"
  on public.berp_push_messages for insert
  to authenticated
  with check (
    app_id = 'berp'
    and public.current_user_role() in ('super_admin', 'hr_manager')
  );

drop policy if exists "push messages update hr" on public.berp_push_messages;
create policy "push messages update hr"
  on public.berp_push_messages for update
  to authenticated
  using (public.current_user_role() in ('super_admin', 'hr_manager'))
  with check (public.current_user_role() in ('super_admin', 'hr_manager'));

-- Staff app may mark a due admin push as sent after showing it locally
drop policy if exists "push messages mark sent staff" on public.berp_push_messages;
create policy "push messages mark sent staff"
  on public.berp_push_messages for update
  to authenticated
  using (app_id = 'berp' and kind = 'admin')
  with check (app_id = 'berp' and kind = 'admin');

drop policy if exists "push messages manage hr" on public.berp_push_messages;
create policy "push messages manage hr"
  on public.berp_push_messages for all
  to authenticated
  using (public.current_user_role() in ('super_admin', 'hr_manager'));

-- Staff can upsert the seeded clock reminder rows they sync from the app
drop policy if exists "push messages upsert clock reminders" on public.berp_push_messages;
create policy "push messages upsert clock reminders"
  on public.berp_push_messages for insert
  to authenticated
  with check (app_id = 'berp' and kind = 'clock_reminder');

drop policy if exists "push deliveries insert own" on public.berp_push_deliveries;
create policy "push deliveries insert own"
  on public.berp_push_deliveries for insert
  to authenticated
  with check (user_id = auth.uid() and app_id = 'berp');

drop policy if exists "push deliveries read own or hr" on public.berp_push_deliveries;
create policy "push deliveries read own or hr"
  on public.berp_push_deliveries for select
  to authenticated
  using (
    user_id = auth.uid()
    or public.current_user_role() in ('super_admin', 'hr_manager')
  );

drop policy if exists "push deliveries manage hr" on public.berp_push_deliveries;
create policy "push deliveries manage hr"
  on public.berp_push_deliveries for all
  to authenticated
  using (public.current_user_role() in ('super_admin', 'hr_manager'));

grant select, insert, update, delete on public.berp_push_messages
  to authenticated, service_role;
grant select, insert, update, delete on public.berp_push_deliveries
  to authenticated, service_role;

-- Seed the four daily clock reminders (visible to admin)
insert into public.berp_push_messages (
  app_id, kind, title, body, recur_time, recur_label, status
)
select v.app_id, v.kind, v.title, v.body, v.recur_time::time, v.recur_label, v.status
from (
  values
    (
      'berp',
      'clock_reminder',
      'Have a beautiful day',
      'Head to work on time — a calm start makes for a beautiful day at VMO.',
      '08:30:00',
      'Every weekday 08:30 Lagos',
      'active'
    ),
    (
      'berp',
      'clock_reminder',
      'Almost time',
      'Get to work on time so you can have a beautiful day. See you at the desk.',
      '08:45:00',
      'Every weekday 08:45 Lagos',
      'active'
    ),
    (
      'berp',
      'clock_reminder',
      'Don''t forget to clock in',
      'Already at work? Clock in now so you do not get a call from HR.',
      '08:55:00',
      'Every weekday 08:55 Lagos',
      'active'
    ),
    (
      'berp',
      'clock_reminder',
      'Clock in now',
      'It is 9:00am Lagos time. Clock in now — after this you may be marked late.',
      '09:00:00',
      'Every weekday 09:00 Lagos',
      'active'
    )
) as v(app_id, kind, title, body, recur_time, recur_label, status)
where not exists (
  select 1
  from public.berp_push_messages m
  where m.app_id = 'berp'
    and m.kind = 'clock_reminder'
    and m.recur_time = v.recur_time::time
);

notify pgrst, 'reload schema';

select kind, title, recur_label, scheduled_at, status
from public.berp_push_messages
where app_id = 'berp'
order by kind, recur_time nulls last, scheduled_at desc nulls last;
