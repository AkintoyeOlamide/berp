-- Profile photos for BERP staff.
-- File lives in Storage; public URL is saved on profiles.avatar_url.

alter table public.profiles
  add column if not exists avatar_url text;

insert into storage.buckets (id, name, public)
values ('berp-avatars', 'berp-avatars', true)
on conflict (id) do nothing;

drop policy if exists "berp avatars public read" on storage.objects;
create policy "berp avatars public read"
  on storage.objects for select
  using (bucket_id = 'berp-avatars');

drop policy if exists "berp avatars own insert" on storage.objects;
create policy "berp avatars own insert"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'berp-avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "berp avatars own update" on storage.objects;
create policy "berp avatars own update"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'berp-avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'berp-avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "berp avatars own delete" on storage.objects;
create policy "berp avatars own delete"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'berp-avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

notify pgrst, 'reload schema';

select column_name
from information_schema.columns
where table_schema = 'public'
  and table_name = 'profiles'
  and column_name = 'avatar_url';
