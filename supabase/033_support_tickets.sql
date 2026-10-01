-- Support tickets (IT / Facility work orders) with photos and admin workflow.
-- Run in Supabase SQL editor after 032:
-- https://supabase.com/dashboard/project/vfrgawklszvhddrvjjxj/sql/new

create table if not exists public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  app_id text not null default 'berp' references public.apps (id),
  reporter_id uuid not null references public.profiles (id) on delete cascade,
  reporter_name text not null default '',
  reporter_email text not null default '',
  category text not null check (category in ('it', 'facility')),
  title text not null,
  description text not null default '',
  location_label text not null default '',
  image_urls text[] not null default '{}',
  status text not null default 'pending'
    check (status in ('pending', 'in_progress', 'done')),
  admin_note text not null default '',
  assigned_to uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_support_tickets_app_created
  on public.support_tickets (app_id, created_at desc);

create index if not exists idx_support_tickets_reporter
  on public.support_tickets (app_id, reporter_id, created_at desc);

create index if not exists idx_support_tickets_status
  on public.support_tickets (app_id, status, created_at desc);

alter table public.support_tickets enable row level security;

drop policy if exists "tickets read own or admin" on public.support_tickets;
create policy "tickets read own or admin"
  on public.support_tickets for select
  to authenticated
  using (
    app_id = 'berp'
    and (
      reporter_id = auth.uid()
      or public.berp_is_org_admin()
    )
  );

drop policy if exists "tickets insert own" on public.support_tickets;
create policy "tickets insert own"
  on public.support_tickets for insert
  to authenticated
  with check (
    app_id = 'berp'
    and reporter_id = auth.uid()
  );

drop policy if exists "tickets update admin" on public.support_tickets;
create policy "tickets update admin"
  on public.support_tickets for update
  to authenticated
  using (public.berp_is_org_admin())
  with check (public.berp_is_org_admin());

grant select, insert, update on public.support_tickets to authenticated, service_role;

-- Optional audience targeting for admin-only push alerts.
alter table public.berp_push_messages
  add column if not exists audience text not null default 'all'
    check (audience in ('all', 'admins'));

create or replace function public.berp_on_support_ticket()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  cat_label text;
begin
  cat_label := case new.category
    when 'it' then 'IT'
    when 'facility' then 'Facility'
    else 'Support'
  end;

  -- In-app notice for every org admin / super admin / hr_manager.
  insert into public.notifications (
    app_id, recipient_user_id, title, message, type, reference_id
  )
  select
    'berp',
    p.id,
    'New ' || cat_label || ' ticket',
    coalesce(nullif(new.title, ''), 'A new work order was submitted'),
    'ticket',
    new.id::text
  from public.profiles p
  where lower(coalesce(p.role, '')) in (
      'admin', 'super_admin', 'hr_manager'
    )
    and coalesce(p.suspended, false) = false
    and p.id is distinct from new.reporter_id;

  -- Push alert targeted at admins only.
  insert into public.berp_push_messages (
    app_id, kind, title, body, scheduled_at, status, created_by, audience
  ) values (
    'berp',
    'admin',
    'New ' || cat_label || ' ticket',
    coalesce(nullif(new.reporter_name, ''), 'Staff') || ': ' ||
      coalesce(nullif(new.title, ''), 'New work order'),
    now(),
    'scheduled',
    new.reporter_id,
    'admins'
  );

  return new;
end $$;

drop trigger if exists berp_on_support_ticket on public.support_tickets;
create trigger berp_on_support_ticket
  after insert on public.support_tickets
  for each row
  execute function public.berp_on_support_ticket();

create or replace function public.berp_on_support_ticket_status()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status is distinct from old.status then
    new.updated_at := now();
    insert into public.notifications (
      app_id, recipient_user_id, title, message, type, reference_id
    ) values (
      'berp',
      new.reporter_id,
      'Ticket update',
      'Your ticket "' || left(new.title, 60) || '" is now ' ||
        replace(new.status, '_', ' ') || '.',
      'ticket',
      new.id::text
    );
  end if;
  return new;
end $$;

drop trigger if exists berp_on_support_ticket_status on public.support_tickets;
create trigger berp_on_support_ticket_status
  before update on public.support_tickets
  for each row
  execute function public.berp_on_support_ticket_status();

notify pgrst, 'reload schema';
