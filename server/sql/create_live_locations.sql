create table if not exists public.live_locations (
  id uuid primary key default gen_random_uuid(),
  alert_id uuid not null references public.alerts(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  latitude double precision not null,
  longitude double precision not null,
  accuracy double precision,
  heading double precision,
  speed double precision,
  source text not null default 'device',
  formatted_address text,
  locality text,
  created_at timestamptz not null default timezone('utc'::text, now()),
  updated_at timestamptz not null default timezone('utc'::text, now())
);

create unique index if not exists live_locations_alert_user_unique_idx
  on public.live_locations (alert_id, user_id);

alter table if exists public.alerts
  add column if not exists updated_at timestamptz not null default timezone('utc'::text, now());

alter table if exists public.users
  add column if not exists created_at timestamptz not null default timezone('utc'::text, now());

alter table if exists public.emergency_contacts
  add column if not exists created_at timestamptz not null default timezone('utc'::text, now());

alter table if exists public.incident_logs
  add column if not exists created_at timestamptz not null default timezone('utc'::text, now());

alter table if exists public.notifications
  add column if not exists created_at timestamptz not null default timezone('utc'::text, now());

create index if not exists live_locations_alert_id_idx
  on public.live_locations (alert_id);

create index if not exists live_locations_user_id_idx
  on public.live_locations (user_id);

create index if not exists live_locations_updated_at_idx
  on public.live_locations (updated_at desc);

create index if not exists alerts_status_created_at_idx
  on public.alerts (status, created_at desc);

alter table public.live_locations replica identity full;
alter table public.alerts replica identity full;
alter table public.notifications replica identity full;

do $$
begin
  alter publication supabase_realtime add table public.alerts;
exception
  when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.live_locations;
exception
  when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.notifications;
exception
  when duplicate_object then null;
end $$;
