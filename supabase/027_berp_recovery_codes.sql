-- BERP 4-digit password recovery (same pattern as vops / 028_vops_recovery_otp.sql).
-- Run in the SQL editor:
-- https://supabase.com/dashboard/project/vfrgawklszvhddrvjjxj/sql/new

create table if not exists public.berp_recovery_codes (
  email text primary key,
  code_hash text not null,
  expires_at timestamptz not null,
  attempts int not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists idx_berp_recovery_codes_expires
  on public.berp_recovery_codes (expires_at);

alter table public.berp_recovery_codes enable row level security;

revoke all on public.berp_recovery_codes from anon, authenticated;
grant all on public.berp_recovery_codes to service_role;

notify pgrst, 'reload schema';

select 'berp_recovery_codes ready' as status;
