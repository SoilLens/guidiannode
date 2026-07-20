-- Extends public.responses (the existing responder-tracking table) with the
-- full community-helper response state machine. Existing values used by the
-- live app ('on_the_way', 'arrived', 'accepted', 'cancelled', 'stopped') stay
-- valid so no in-flight or historical response breaks.

alter table if exists public.responses
  add column if not exists capability text;

alter table if exists public.responses
  add column if not exists eta_minutes integer;

alter table if exists public.responses
  add column if not exists note text;

alter table public.responses drop constraint if exists responses_status_check;
alter table public.responses add constraint responses_status_check check (
  response_status in (
    'offered',
    'accepted',
    'on_the_way',
    'en_route',
    'arrived',
    'assistance_in_progress',
    'completed',
    'cancelled',
    'unable_to_assist',
    'stopped'
  )
);

create index if not exists responses_status_idx on public.responses (response_status);

notify pgrst, 'reload schema';
