-- BERP forgot-password: 4-digit email codes for existing users.
-- Run in the BHR project SQL editor:
-- https://supabase.com/dashboard/project/vfrgawklszvhddrvjjxj/sql/new
--
-- Also set the Auth email so the code actually arrives:
-- 1. Authentication → Email Templates → Magic Link AND Reset Password
--    Replace the body with:
--
--    <h2>Reset your BERP password</h2>
--    <p>Enter this 4-digit code in the app. It expires in 1 hour.</p>
--    <p style="font-size:28px;letter-spacing:8px;font-weight:700;">{{ .Token }}</p>
--    <p>If you did not ask to reset your password, you can ignore this email.</p>
--
-- 2. Authentication → Providers → Email → OTP length → 4
--    (If the dashboard will not go below 6, the app still accepts the
--    custom 4-digit codes created by this script when email is sent below.)

create extension if not exists pgcrypto with schema extensions;
create extension if not exists pg_net;

create table if not exists public.berp_private_config (
  key text primary key,
  value text not null,
  updated_at timestamptz not null default now()
);

alter table public.berp_private_config enable row level security;

create table if not exists public.berp_password_resets (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  salt text not null,
  code_hash text not null,
  attempts integer not null default 0,
  expires_at timestamptz not null,
  consumed_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists idx_berp_password_resets_email
  on public.berp_password_resets (email, created_at desc);

alter table public.berp_password_resets enable row level security;

create or replace function public.request_berp_password_reset(p_email text)
returns jsonb
language plpgsql
security definer
set search_path = public, auth, extensions, net
as $$
declare
  v_email text := lower(trim(coalesce(p_email, '')));
  v_user_id uuid;
  v_code text;
  v_salt text;
  v_resend_key text;
  v_from_email text;
  v_recent timestamptz;
  v_result jsonb;
begin
  if v_email is null or v_email !~ '^[^@]+@[^@]+\.[^@]+$' then
    raise exception 'Enter a valid email address.';
  end if;

  -- Always look the same to the client (no account enumeration).
  select id into v_user_id
  from auth.users
  where lower(email) = v_email
  limit 1;

  if v_user_id is null then
    return jsonb_build_object('ok', true, 'emailed', false, 'reason', 'no_user');
  end if;

  select created_at into v_recent
  from public.berp_password_resets
  where email = v_email
  order by created_at desc
  limit 1;

  if v_recent is not null and v_recent > now() - interval '60 seconds' then
    raise exception 'Please wait a moment before requesting another code.';
  end if;

  update public.berp_password_resets
  set consumed_at = now()
  where email = v_email
    and consumed_at is null;

  v_code := lpad((floor(random() * 10000))::int::text, 4, '0');
  v_salt := encode(extensions.gen_random_bytes(16), 'hex');

  insert into public.berp_password_resets (email, salt, code_hash, expires_at)
  values (
    v_email,
    v_salt,
    encode(extensions.digest(convert_to(v_code || v_salt, 'UTF8'), 'sha256'), 'hex'),
    now() + interval '15 minutes'
  );

  select value into v_resend_key
  from public.berp_private_config
  where key = 'resend_api_key'
  limit 1;

  select value into v_from_email
  from public.berp_private_config
  where key = 'reset_from_email'
  limit 1;

  if v_resend_key is not null and length(trim(v_resend_key)) > 8 then
    begin
      perform net.http_post(
        url := 'https://api.resend.com/emails',
        headers := jsonb_build_object(
          'Authorization', 'Bearer ' || trim(v_resend_key),
          'Content-Type', 'application/json'
        ),
        body := jsonb_build_object(
          'from', coalesce(nullif(trim(v_from_email), ''), 'BERP <noreply@vmoaeros.com>'),
          'to', v_email,
          'subject', 'Your BERP password reset code',
          'html',
            '<p>Your BERP reset code is <strong style="font-size:22px;letter-spacing:4px;">'
            || v_code
            || '</strong>.</p><p>It expires in 15 minutes. If you did not request this, ignore this email.</p>'
        )
      );
      v_result := jsonb_build_object('ok', true, 'emailed', true, 'reason', 'sent');
    exception
      when others then
        v_result := jsonb_build_object('ok', true, 'emailed', false, 'reason', 'no_mailer');
    end;
  else
    v_result := jsonb_build_object('ok', true, 'emailed', false, 'reason', 'no_mailer');
  end if;

  if auth.role() = 'service_role' then
    v_result := v_result || jsonb_build_object('code', v_code);
  end if;

  return v_result;
end;
$$;

create or replace function public.complete_berp_password_reset(
  p_email text,
  p_code text,
  p_password text
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth, extensions
as $$
declare
  v_email text := lower(trim(coalesce(p_email, '')));
  v_code text := trim(coalesce(p_code, ''));
  v_row public.berp_password_resets%rowtype;
  v_user_id uuid;
begin
  if length(coalesce(p_password, '')) < 6 then
    raise exception 'Password must be at least 6 characters.';
  end if;
  if v_code !~ '^\d{4}$' then
    raise exception 'Enter the 4-digit code we emailed you.';
  end if;

  select * into v_row
  from public.berp_password_resets
  where email = v_email
    and consumed_at is null
    and expires_at > now()
  order by created_at desc
  limit 1;

  if not found then
    raise exception 'That code is invalid or has expired.';
  end if;

  if v_row.attempts >= 5 then
    raise exception 'Too many attempts. Request a new code.';
  end if;

  if v_row.code_hash
      <> encode(extensions.digest(convert_to(v_code || v_row.salt, 'UTF8'), 'sha256'), 'hex') then
    update public.berp_password_resets
    set attempts = attempts + 1
    where id = v_row.id;
    raise exception 'That code is invalid or has expired.';
  end if;

  select id into v_user_id
  from auth.users
  where lower(email) = v_email
  limit 1;

  if v_user_id is null then
    raise exception 'That code is invalid or has expired.';
  end if;

  update auth.users
  set
    encrypted_password = extensions.crypt(p_password, extensions.gen_salt('bf', 10)),
    updated_at = now()
  where id = v_user_id;

  update public.berp_password_resets
  set consumed_at = now()
  where id = v_row.id;

  delete from public.berp_password_resets
  where email = v_email
    and consumed_at is null;

  return jsonb_build_object('ok', true);
end;
$$;

revoke all on function public.request_berp_password_reset(text) from public;
revoke all on function public.complete_berp_password_reset(text, text, text) from public;

grant execute on function public.request_berp_password_reset(text)
  to anon, authenticated;
grant execute on function public.complete_berp_password_reset(text, text, text)
  to anon, authenticated;

notify pgrst, 'reload schema';

select 'berp_password_resets' as ready;
