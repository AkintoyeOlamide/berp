-- BERP roles, clock locations, leave handover, and notifications.
-- Run in the shared BHR/BERP SQL editor. Existing clock, leave, and
-- profile rows stay. Passwords are not created here.

-- Role values used by BERP. employee and hr_manager stay valid so
-- existing Bitachon HR rows are not rejected.
do $$
declare r record;
begin
  for r in
    select conname
    from pg_constraint
    where conrelid = 'public.profiles'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) ilike '%role%'
  loop
    execute format('alter table public.profiles drop constraint %I', r.conname);
  end loop;
end $$;

alter table public.profiles
  add column if not exists manager_id uuid;

alter table public.profiles
  drop constraint if exists profiles_role_check;

-- Normalize any legacy / Bitachon role strings before the check is added.
update public.profiles
set role = case
  when role is null or btrim(role) = '' then 'staff'
  when lower(btrim(role)) in ('super_admin', 'superadmin', 'super-admin')
    then 'super_admin'
  when lower(btrim(role)) in ('admin', 'administrator', 'org_admin')
    then 'admin'
  when lower(btrim(role)) in ('hr_manager', 'hr', 'people', 'hr_admin')
    then 'hr_manager'
  when lower(btrim(role)) in ('manager', 'team_manager', 'line_manager')
    then 'manager'
  when lower(btrim(role)) in ('staff', 'employee', 'user', 'member')
    then case
      when lower(btrim(role)) = 'employee' then 'employee'
      else 'staff'
    end
  else 'staff'
end
where role is null
   or btrim(role) = ''
   or lower(btrim(role)) not in (
     'staff',
     'employee',
     'manager',
     'admin',
     'hr_manager',
     'super_admin'
   );

alter table public.profiles
  add constraint profiles_role_check
  check (
    role is null
    or role in (
      'staff',
      'employee',
      'manager',
      'admin',
      'hr_manager',
      'super_admin'
    )
  );

create or replace function public.berp_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid()
$$;

create or replace function public.berp_is_org_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.berp_role() in ('admin', 'super_admin', 'hr_manager')
$$;

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
  elsif new.role is null or btrim(new.role) = '' then
    new.role := 'staff';
  end if;
  return new;
end $$;

drop trigger if exists berp_assign_founders on public.profiles;
create trigger berp_assign_founders
  before insert on public.profiles
  for each row
  execute function public.berp_assign_founders();

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

drop trigger if exists berp_guard_role on public.profiles;
create trigger berp_guard_role
  before update on public.profiles
  for each row
  execute function public.berp_guard_role();

update public.profiles
set role = 'super_admin'
where lower(email) in ('olamide@vmoaeros.com', 'akintoyelmd@gmail.com');

alter table public.profiles
  add column if not exists suspended boolean not null default false;

alter table public.profiles
  add column if not exists suspended_at timestamptz;

alter table public.profiles
  add column if not exists suspended_by uuid references public.profiles (id);

alter table public.profiles
  add column if not exists suspended_reason text not null default '';

-- Clock-in places. The Ikeja pin remains the default active site.
create table if not exists public.clock_locations (
  id uuid primary key default gen_random_uuid(),
  app_id text not null default 'berp' references public.apps (id),
  name text not null,
  address text not null default '',
  latitude double precision not null,
  longitude double precision not null,
  radius_meters integer not null default 150,
  is_active boolean not null default true,
  created_by uuid references public.profiles (id),
  created_at timestamptz not null default now()
);

insert into public.clock_locations (
  app_id, name, address, latitude, longitude, radius_meters, is_active
)
select
  'berp',
  '47a Oduduwa Crescent — Ikeja GRA',
  '47a Oduduwa Crescent, Ikeja GRA',
  6.5729595,
  3.3523593,
  150,
  true
where not exists (
  select 1 from public.clock_locations
  where app_id = 'berp'
    and abs(latitude - 6.5729595) < 0.0001
    and abs(longitude - 3.3523593) < 0.0001
);

alter table public.clock_sessions
  add column if not exists location_id uuid references public.clock_locations (id),
  add column if not exists clock_in_lat double precision,
  add column if not exists clock_in_lng double precision,
  add column if not exists clock_out_lat double precision,
  add column if not exists clock_out_lng double precision;

create table if not exists public.clock_session_locations (
  id uuid primary key default gen_random_uuid(),
  clock_session_id uuid not null references public.clock_sessions (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  latitude double precision not null,
  longitude double precision not null,
  recorded_at timestamptz not null default now()
);

create index if not exists idx_session_locations_session
  on public.clock_session_locations (clock_session_id, recorded_at desc);

alter table public.leave_requests
  add column if not exists handover_email text not null default '',
  add column if not exists handover_note text not null default '',
  add column if not exists handover_file_url text not null default '',
  add column if not exists decided_by uuid references public.profiles (id),
  add column if not exists decided_at timestamptz;

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  app_id text not null default 'berp' references public.apps (id),
  recipient_user_id uuid not null references public.profiles (id) on delete cascade,
  title text not null,
  message text not null default '',
  type text not null default 'general',
  reference_id text,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists idx_notifications_recipient
  on public.notifications (recipient_user_id, created_at desc);

create or replace function public.berp_notify(
  recipient uuid,
  title text,
  message text,
  kind text,
  reference_id text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  actor uuid := auth.uid();
  allowed boolean := false;
begin
  if actor is null or recipient is null then
    return;
  end if;
  if public.berp_is_org_admin() then
    allowed := true;
  elsif recipient = (select manager_id from public.profiles where id = actor) then
    allowed := true;
  elsif exists (
    select 1
    from public.leave_requests lr
    join public.profiles hp on lower(hp.email) = lower(lr.handover_email)
    where lr.user_id = actor
      and hp.id = recipient
      and lr.created_at > now() - interval '1 day'
  ) then
    allowed := true;
  elsif exists (
    select 1
    from public.profiles member
    where member.id = recipient
      and member.manager_id = actor
  ) then
    allowed := true;
  end if;
  if not allowed then
    return;
  end if;
  insert into public.notifications (
    app_id, recipient_user_id, title, message, type, reference_id
  ) values (
    'berp', recipient, title, coalesce(message, ''), coalesce(kind, 'general'), reference_id
  );
end $$;

grant execute on function public.berp_role() to authenticated;
grant execute on function public.berp_is_org_admin() to authenticated;
grant execute on function public.berp_notify(uuid, text, text, text, text) to authenticated;

alter table public.clock_locations enable row level security;
alter table public.clock_session_locations enable row level security;
alter table public.notifications enable row level security;

drop policy if exists "clock locations read active or admin" on public.clock_locations;
create policy "clock locations read active or admin"
  on public.clock_locations for select
  to authenticated
  using (is_active or public.berp_is_org_admin());

drop policy if exists "clock locations write admin" on public.clock_locations;
create policy "clock locations write admin"
  on public.clock_locations for all
  to authenticated
  using (public.berp_is_org_admin())
  with check (public.berp_is_org_admin());

drop policy if exists "profiles read team or admin" on public.profiles;
create policy "profiles read team or admin"
  on public.profiles for select
  to authenticated
  using (
    id = auth.uid()
    or manager_id = auth.uid()
    or public.berp_is_org_admin()
  );

drop policy if exists "profiles update admin" on public.profiles;
create policy "profiles update admin"
  on public.profiles for update
  to authenticated
  using (public.berp_is_org_admin())
  with check (public.berp_is_org_admin());

drop policy if exists "clock read admin" on public.clock_sessions;
create policy "clock read admin"
  on public.clock_sessions for select
  to authenticated
  using (user_id = auth.uid() or public.berp_is_org_admin());

drop policy if exists "session locations own or admin" on public.clock_session_locations;
create policy "session locations own or admin"
  on public.clock_session_locations for select
  to authenticated
  using (user_id = auth.uid() or public.berp_is_org_admin());

drop policy if exists "session locations insert own open" on public.clock_session_locations;
create policy "session locations insert own open"
  on public.clock_session_locations for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.clock_sessions s
      where s.id = clock_session_id
        and s.user_id = auth.uid()
        and s.clock_out is null
    )
  );

drop policy if exists "leave read manager team" on public.leave_requests;
create policy "leave read manager team"
  on public.leave_requests for select
  to authenticated
  using (
    user_id = auth.uid()
    or public.berp_is_org_admin()
    or exists (
      select 1 from public.profiles p
      where p.id = leave_requests.user_id
        and p.manager_id = auth.uid()
    )
  );

drop policy if exists "leave decide manager or admin" on public.leave_requests;
create policy "leave decide manager or admin"
  on public.leave_requests for update
  to authenticated
  using (
    public.berp_is_org_admin()
    or exists (
      select 1 from public.profiles p
      where p.id = leave_requests.user_id
        and p.manager_id = auth.uid()
    )
  )
  with check (
    public.berp_is_org_admin()
    or exists (
      select 1 from public.profiles p
      where p.id = leave_requests.user_id
        and p.manager_id = auth.uid()
    )
  );

drop policy if exists "updates insert own" on public.staff_updates;
drop policy if exists "updates insert admin" on public.staff_updates;
create policy "updates insert admin"
  on public.staff_updates for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and public.berp_is_org_admin()
  );

drop policy if exists "notifications read own" on public.notifications;
create policy "notifications read own"
  on public.notifications for select
  to authenticated
  using (recipient_user_id = auth.uid());

drop policy if exists "notifications mark own" on public.notifications;
create policy "notifications mark own"
  on public.notifications for update
  to authenticated
  using (recipient_user_id = auth.uid())
  with check (recipient_user_id = auth.uid());

drop policy if exists "berp manager read appraisals" on public.appraisals;
create policy "berp manager read appraisals"
  on public.appraisals for select
  to authenticated
  using (
    public.berp_is_org_admin()
    or exists (
      select 1
      from public.legacy_employee_profiles rev
      join public.profiles me on lower(me.email) = lower(rev.email)
      where rev.id = appraisals.reviewer_id
        and me.id = auth.uid()
    )
    or exists (
      select 1
      from public.legacy_employee_profiles lep
      join public.profiles member on lower(member.email) = lower(lep.email)
      where lep.id = appraisals.employee_id
        and member.manager_id = auth.uid()
    )
  );

drop policy if exists "berp reviewer update appraisals" on public.appraisals;
create policy "berp reviewer update appraisals"
  on public.appraisals for update
  to authenticated
  using (
    public.berp_is_org_admin()
    or exists (
      select 1
      from public.legacy_employee_profiles rev
      join public.profiles me on lower(me.email) = lower(rev.email)
      where rev.id = appraisals.reviewer_id
        and me.id = auth.uid()
    )
  );

grant select, insert, update on public.clock_locations to authenticated;
grant select, insert on public.clock_session_locations to authenticated;
grant select, update on public.notifications to authenticated;

do $$
begin
  alter publication supabase_realtime add table public.clock_sessions;
exception
  when duplicate_object then null;
  when undefined_object then null;
end $$;

create or replace function public.berp_on_leave_event()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  manager uuid;
  handover uuid;
  who text;
begin
  if tg_op = 'INSERT' then
    select p.manager_id, p.full_name into manager, who
    from public.profiles p
    where p.id = new.user_id;
    if manager is not null then
      insert into public.notifications (
        app_id, recipient_user_id, title, message, type, reference_id
      ) values (
        'berp',
        manager,
        'Leave request',
        coalesce(who, 'A team member') || ' requested ' || new.kind || ' leave.',
        'leave',
        new.id::text
      );
    end if;
    if btrim(coalesce(new.handover_email, '')) <> '' then
      select id into handover
      from public.profiles
      where lower(email) = lower(new.handover_email)
      limit 1;
      if handover is not null and handover is distinct from new.user_id then
        insert into public.notifications (
          app_id, recipient_user_id, title, message, type, reference_id
        ) values (
          'berp',
          handover,
          'Handover assigned',
          coalesce(who, 'A colleague') || ' named you as handover for their leave. You do not approve it.',
          'handover',
          new.id::text
        );
      end if;
    end if;
    return new;
  end if;

  if new.status is distinct from old.status then
    insert into public.notifications (
      app_id, recipient_user_id, title, message, type, reference_id
    ) values (
      'berp',
      new.user_id,
      'Leave ' || new.status,
      'Your ' || new.kind || ' leave was ' || new.status || '.',
      'leave',
      new.id::text
    );
  end if;
  return new;
end $$;

drop trigger if exists berp_on_leave_event on public.leave_requests;
create trigger berp_on_leave_event
  after insert or update on public.leave_requests
  for each row
  execute function public.berp_on_leave_event();

create or replace function public.berp_on_staff_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.notifications (
    app_id, recipient_user_id, title, message, type, reference_id
  )
  select
    'berp',
    p.id,
    'Staff update',
    new.title,
    'update',
    new.id::text
  from public.profiles p;
  return new;
end $$;

drop trigger if exists berp_on_staff_update on public.staff_updates;
create trigger berp_on_staff_update
  after insert on public.staff_updates
  for each row
  execute function public.berp_on_staff_update();

create or replace function public.berp_on_appraisal_assigned()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  recipient uuid;
  emp_name text;
begin
  select p.id into recipient
  from public.legacy_employee_profiles rev
  join public.profiles p on lower(p.email) = lower(rev.email)
  where rev.id = new.reviewer_id
  limit 1;
  if recipient is null then
    return new;
  end if;
  select full_name into emp_name
  from public.legacy_employee_profiles
  where id = new.employee_id;
  insert into public.notifications (
    app_id, recipient_user_id, title, message, type, reference_id
  ) values (
    'berp',
    recipient,
    'Appraisal assigned',
    coalesce(nullif(emp_name, ''), 'A team member') || ' has an appraisal form for you.',
    'appraisal',
    new.id::text
  );
  return new;
end $$;

drop trigger if exists berp_on_appraisal_assigned on public.appraisals;
create trigger berp_on_appraisal_assigned
  after insert on public.appraisals
  for each row
  execute function public.berp_on_appraisal_assigned();

notify pgrst, 'reload schema';
