-- Community trust signals for an alert: confirm, dispute, or flag as a false
-- report. One row per (alert_id, user_id) so a single user cannot repeatedly
-- confirm the same incident; they may change their own confirmation type via
-- upsert instead of inserting duplicates.

create table if not exists public.alert_confirmations (
  id uuid primary key default gen_random_uuid(),
  alert_id uuid not null references public.alerts(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  confirmation_type text not null,
  note text,
  created_at timestamptz not null default timezone('utc'::text, now()),
  updated_at timestamptz not null default timezone('utc'::text, now())
);

alter table public.alert_confirmations drop constraint if exists alert_confirmations_type_check;
alter table public.alert_confirmations add constraint alert_confirmations_type_check check (
  confirmation_type in ('community_confirm', 'dispute', 'false_report')
);

create unique index if not exists alert_confirmations_alert_user_unique_idx
  on public.alert_confirmations (alert_id, user_id);

create index if not exists alert_confirmations_alert_id_idx
  on public.alert_confirmations (alert_id);

alter table public.alert_confirmations replica identity full;

do $$
begin
  alter publication supabase_realtime add table public.alert_confirmations;
exception
  when duplicate_object then null;
end $$;

notify pgrst, 'reload schema';
