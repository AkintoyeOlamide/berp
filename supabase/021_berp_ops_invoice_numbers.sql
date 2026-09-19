-- BERP OPS: invoices get their own number sequence, separate from quotes.
-- Run after 020_berp_ops_quotes.sql:
-- https://supabase.com/dashboard/project/vfrgawklszvhddrvjjxj/sql/new

-- An invoice number is optional (quotes have none) but must be unique per app
-- once assigned. A partial unique index allows many NULLs.
create unique index if not exists idx_ops_quotes_app_invoice_number
  on public.ops_quotes (app_id, invoice_number)
  where invoice_number is not null;

-- Invoices must carry a number; quotes must not.
alter table public.ops_quotes
  drop constraint if exists ops_quotes_invoice_number_required;

alter table public.ops_quotes
  add constraint ops_quotes_invoice_number_required
  check (
    (status = 'invoice' and invoice_number is not null)
    or status <> 'invoice'
  );

notify pgrst, 'reload schema';

select
  indexname
from pg_indexes
where schemaname = 'public'
  and tablename = 'ops_quotes'
  and indexname = 'idx_ops_quotes_app_invoice_number';
