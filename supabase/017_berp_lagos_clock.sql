-- Lagos wall-clock text the admin can display as-is.
-- Real instants stay in clock_in / clock_out (timestamptz).

alter table public.clock_sessions
  add column if not exists clock_in_lagos text;

alter table public.clock_sessions
  add column if not exists clock_out_lagos text;

create or replace function public.berp_stamp_lagos_clock()
returns trigger
language plpgsql
as $$
begin
  new.clock_in_lagos :=
    to_char(timezone('Africa/Lagos', new.clock_in), 'DD Mon YYYY, HH24:MI:SS');
  if new.clock_out is null then
    new.clock_out_lagos := null;
  else
    new.clock_out_lagos :=
      to_char(timezone('Africa/Lagos', new.clock_out), 'DD Mon YYYY, HH24:MI:SS');
  end if;
  return new;
end;
$$;

drop trigger if exists berp_stamp_lagos_clock on public.clock_sessions;
create trigger berp_stamp_lagos_clock
  before insert or update on public.clock_sessions
  for each row execute function public.berp_stamp_lagos_clock();

update public.clock_sessions
set clock_in = clock_in;

notify pgrst, 'reload schema';

select id, clock_in_lagos, clock_out_lagos
from public.clock_sessions
order by clock_in desc
limit 20;
