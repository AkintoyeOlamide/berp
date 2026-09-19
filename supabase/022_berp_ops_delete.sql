-- Allow staff to delete their own OPS quotes / invoices.
-- HR / super_admin already have FOR ALL via 020.

drop policy if exists "ops quotes delete own" on public.ops_quotes;
create policy "ops quotes delete own"
  on public.ops_quotes for delete
  to authenticated
  using (user_id = auth.uid());

notify pgrst, 'reload schema';
