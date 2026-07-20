-- Enables Row Level Security across every table the Flutter client can see
-- through the public anon key (Supabase Realtime) or could reach with a
-- direct PostgREST call, and locks writes to the backend's service-role
-- client (service_role always bypasses RLS, so this file never restricts
-- server-side Node code).
--
-- IMPORTANT ARCHITECTURE NOTE: the Flutter app authenticates against the
-- Node backend (WhatsApp-verification + app-issued JWT), not against
-- Supabase Auth on the client. Realtime connections therefore run as the
-- anonymous Postgres role with no auth.uid(). That means per-row ownership
-- policies (e.g. "only see your own notification") cannot be enforced by RLS
-- today without a larger change that gives the client a real Supabase Auth
-- session. Until that migration happens, the tables the app already
-- broadcasts broadly (alerts, live_locations, responses, notifications,
-- alert_confirmations) keep an open SELECT policy for anon/authenticated so
-- existing realtime features keep working exactly as before. Every other
-- table -- especially users and emergency_contacts, which hold phone numbers
-- and home locations -- is fully locked down: the anon key can no longer
-- read them directly, closing off a real PII exposure that existed as soon
-- as the public anon key left the building inside the compiled app.
--
-- All INSERT/UPDATE/DELETE policies for anon/authenticated are intentionally
-- omitted (default deny once RLS is enabled), because every write in this
-- application already flows through the backend's service-role client.

alter table public.users enable row level security;
alter table public.emergency_contacts enable row level security;
alter table public.otp_sessions enable row level security;
alter table public.alerts enable row level security;
alter table public.live_locations enable row level security;
alter table public.responses enable row level security;
alter table public.notifications enable row level security;
alter table public.incident_logs enable row level security;
alter table public.alert_confirmations enable row level security;
alter table public.moderation_actions enable row level security;
alter table public.alert_media enable row level security;

-- Tables the client subscribes to directly via Supabase Realtime today.
-- Read-only for anon/authenticated; no write policies.

drop policy if exists alerts_public_read on public.alerts;
create policy alerts_public_read on public.alerts
  for select to anon, authenticated using (true);

drop policy if exists live_locations_public_read on public.live_locations;
create policy live_locations_public_read on public.live_locations
  for select to anon, authenticated using (true);

drop policy if exists responses_public_read on public.responses;
create policy responses_public_read on public.responses
  for select to anon, authenticated using (true);

drop policy if exists notifications_public_read on public.notifications;
create policy notifications_public_read on public.notifications
  for select to anon, authenticated using (true);

drop policy if exists alert_confirmations_public_read on public.alert_confirmations;
create policy alert_confirmations_public_read on public.alert_confirmations
  for select to anon, authenticated using (true);

-- Everything else (users, emergency_contacts, otp_sessions, incident_logs,
-- moderation_actions, alert_media) has RLS enabled with zero anon/
-- authenticated policies, i.e. fully deny-by-default for those roles. The
-- Flutter client never reads these tables directly today, so this is purely
-- additive hardening with no functional change.

notify pgrst, 'reload schema';
