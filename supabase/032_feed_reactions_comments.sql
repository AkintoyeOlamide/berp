-- Feed reactions, comments, and org-admin push for staff updates.
-- Run in Supabase SQL editor after 031:
-- https://supabase.com/dashboard/project/vfrgawklszvhddrvjjxj/sql/new

create table if not exists public.staff_update_reactions (
  id uuid primary key default gen_random_uuid(),
  app_id text not null default 'berp' references public.apps (id),
  update_id uuid not null references public.staff_updates (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  reaction text not null check (reaction in ('like', 'love', 'clap', 'insight')),
  created_at timestamptz not null default now(),
  unique (update_id, user_id)
);

create index if not exists idx_staff_update_reactions_update
  on public.staff_update_reactions (update_id, created_at desc);

create table if not exists public.staff_update_comments (
  id uuid primary key default gen_random_uuid(),
  app_id text not null default 'berp' references public.apps (id),
  update_id uuid not null references public.staff_updates (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  author_name text not null default '',
  body text not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_staff_update_comments_update
  on public.staff_update_comments (update_id, created_at asc);

alter table public.staff_update_reactions enable row level security;
alter table public.staff_update_comments enable row level security;

drop policy if exists "feed reactions read berp" on public.staff_update_reactions;
create policy "feed reactions read berp"
  on public.staff_update_reactions for select
  to authenticated
  using (app_id = 'berp');

drop policy if exists "feed reactions upsert own" on public.staff_update_reactions;
create policy "feed reactions upsert own"
  on public.staff_update_reactions for insert
  to authenticated
  with check (app_id = 'berp' and user_id = auth.uid());

drop policy if exists "feed reactions update own" on public.staff_update_reactions;
create policy "feed reactions update own"
  on public.staff_update_reactions for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "feed reactions delete own" on public.staff_update_reactions;
create policy "feed reactions delete own"
  on public.staff_update_reactions for delete
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "feed comments read berp" on public.staff_update_comments;
create policy "feed comments read berp"
  on public.staff_update_comments for select
  to authenticated
  using (app_id = 'berp');

drop policy if exists "feed comments insert own" on public.staff_update_comments;
create policy "feed comments insert own"
  on public.staff_update_comments for insert
  to authenticated
  with check (app_id = 'berp' and user_id = auth.uid());

drop policy if exists "feed comments delete own" on public.staff_update_comments;
create policy "feed comments delete own"
  on public.staff_update_comments for delete
  to authenticated
  using (
    user_id = auth.uid()
    or public.berp_is_org_admin()
  );

grant select, insert, update, delete on public.staff_update_reactions to authenticated, service_role;
grant select, insert, delete on public.staff_update_comments to authenticated, service_role;

-- Allow org admins (admin + super_admin) to schedule push messages.
drop policy if exists "push messages insert hr" on public.berp_push_messages;
drop policy if exists "push messages insert admin" on public.berp_push_messages;
create policy "push messages insert admin"
  on public.berp_push_messages for insert
  to authenticated
  with check (
    app_id = 'berp'
    and (
      public.berp_is_org_admin()
      or public.current_user_role() in ('super_admin', 'hr_manager', 'admin')
    )
  );

drop policy if exists "push messages update hr" on public.berp_push_messages;
drop policy if exists "push messages update admin" on public.berp_push_messages;
create policy "push messages update admin"
  on public.berp_push_messages for update
  to authenticated
  using (
    public.berp_is_org_admin()
    or public.current_user_role() in ('super_admin', 'hr_manager', 'admin')
  )
  with check (
    public.berp_is_org_admin()
    or public.current_user_role() in ('super_admin', 'hr_manager', 'admin')
  );

drop policy if exists "push messages manage hr" on public.berp_push_messages;
drop policy if exists "push messages manage admin" on public.berp_push_messages;
create policy "push messages manage admin"
  on public.berp_push_messages for all
  to authenticated
  using (
    public.berp_is_org_admin()
    or public.current_user_role() in ('super_admin', 'hr_manager', 'admin')
  );

-- Prefer notifying everyone except the author.
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
    'New update',
    new.title,
    'update',
    new.id::text
  from public.profiles p
  where p.id is distinct from new.user_id
    and coalesce(p.suspended, false) = false;
  return new;
end $$;

notify pgrst, 'reload schema';
