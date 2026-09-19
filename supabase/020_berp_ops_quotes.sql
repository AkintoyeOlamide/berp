-- BERP OPS quotes / invoices. Same Supabase project as BHR.
-- Run in the SQL editor after 016–019:
-- https://supabase.com/dashboard/project/vfrgawklszvhddrvjjxj/sql/new

create table if not exists public.ops_quotes (
  id uuid primary key default gen_random_uuid(),
  app_id text not null references public.apps (id),
  user_id uuid not null references public.profiles (id) on delete cascade,
  quote_number int not null,
  invoice_number int,
  status text not null default 'quote'
    check (status in ('quote', 'invoice')),
  quote_date date not null,
  invoice_date date,
  client_name text not null default '',
  contact_name text not null default '',
  aircraft_id text not null default '',
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists idx_ops_quotes_app_number
  on public.ops_quotes (app_id, quote_number);

create index if not exists idx_ops_quotes_app_user
  on public.ops_quotes (app_id, user_id, quote_number desc);

alter table public.ops_quotes enable row level security;

drop policy if exists "ops quotes read own or hr" on public.ops_quotes;
create policy "ops quotes read own or hr"
  on public.ops_quotes for select
  to authenticated
  using (
    user_id = auth.uid()
    or public.current_user_role() in ('super_admin', 'hr_manager')
  );

drop policy if exists "ops quotes insert own" on public.ops_quotes;
create policy "ops quotes insert own"
  on public.ops_quotes for insert
  to authenticated
  with check (user_id = auth.uid() and app_id = 'berp');

drop policy if exists "ops quotes update own" on public.ops_quotes;
create policy "ops quotes update own"
  on public.ops_quotes for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "ops quotes manage hr" on public.ops_quotes;
create policy "ops quotes manage hr"
  on public.ops_quotes for all
  to authenticated
  using (public.current_user_role() in ('super_admin', 'hr_manager'));

grant select, insert, update, delete on public.ops_quotes
  to authenticated, service_role;

notify pgrst, 'reload schema';

select table_name
from information_schema.tables
where table_schema = 'public'
  and table_name = 'ops_quotes';
