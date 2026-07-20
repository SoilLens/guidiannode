-- Extends public.alerts with multilingual free-text reporting, AI-assisted
-- triage (advisory only), and incident verification/trust fields.
-- emergency_type remains the legacy quick-SOS category; confirmed_category /
-- suggested_category carry the richer crisis taxonomy used by the free-text
-- report flow and by moderators.

alter table if exists public.alerts
  add column if not exists original_description text;

alter table if exists public.alerts
  add column if not exists normalised_description text;

alter table if exists public.alerts
  add column if not exists detected_language text not null default 'unknown';

alter table if exists public.alerts
  add column if not exists suggested_category text;

alter table if exists public.alerts
  add column if not exists confirmed_category text;

alter table if exists public.alerts
  add column if not exists urgency_level text;

alter table if exists public.alerts
  add column if not exists classification_confidence numeric(4,3);

alter table if exists public.alerts
  add column if not exists classification_source text not null default 'user';

alter table if exists public.alerts
  add column if not exists ai_explanation text;

alter table if exists public.alerts
  add column if not exists recommended_action text;

alter table if exists public.alerts
  add column if not exists requires_moderator_attention boolean not null default false;

alter table if exists public.alerts
  add column if not exists possible_spam boolean not null default false;

alter table if exists public.alerts
  add column if not exists verification_status text not null default 'unverified';

alter table if exists public.alerts
  add column if not exists visibility_level text not null default 'standard';

alter table if exists public.alerts
  add column if not exists people_affected integer;

alter table if exists public.alerts
  add column if not exists assistance_needed text[] not null default '{}'::text[];

alter table if exists public.alerts
  add column if not exists moderation_status text not null default 'pending_review';

alter table if exists public.alerts
  add column if not exists moderated_by uuid references public.users(id) on delete set null;

alter table if exists public.alerts
  add column if not exists moderated_at timestamptz;

alter table if exists public.alerts
  add column if not exists moderation_notes text;

alter table if exists public.alerts
  add column if not exists resolved_at timestamptz;

alter table public.alerts drop constraint if exists alerts_detected_language_check;
alter table public.alerts add constraint alerts_detected_language_check check (
  detected_language in ('en', 'fr', 'pcm', 'unknown')
);

alter table public.alerts drop constraint if exists alerts_urgency_level_check;
alter table public.alerts add constraint alerts_urgency_level_check check (
  urgency_level is null or urgency_level in ('critical', 'high', 'medium', 'low')
);

alter table public.alerts drop constraint if exists alerts_classification_source_check;
alter table public.alerts add constraint alerts_classification_source_check check (
  classification_source in ('ai', 'rules', 'user', 'moderator')
);

alter table public.alerts drop constraint if exists alerts_verification_status_check;
alter table public.alerts add constraint alerts_verification_status_check check (
  verification_status in (
    'unverified',
    'community_confirmed',
    'responder_confirmed',
    'officially_confirmed',
    'disputed',
    'false_report',
    'resolved'
  )
);

alter table public.alerts drop constraint if exists alerts_visibility_level_check;
alter table public.alerts add constraint alerts_visibility_level_check check (
  visibility_level in ('standard', 'sensitive', 'restricted')
);

alter table public.alerts drop constraint if exists alerts_moderation_status_check;
alter table public.alerts add constraint alerts_moderation_status_check check (
  moderation_status in ('pending_review', 'reviewed', 'flagged', 'actioned')
);

create index if not exists alerts_verification_status_idx on public.alerts (verification_status);
create index if not exists alerts_urgency_level_idx on public.alerts (urgency_level);
create index if not exists alerts_confirmed_category_idx on public.alerts (confirmed_category);
create index if not exists alerts_moderation_status_idx
  on public.alerts (moderation_status)
  where moderation_status in ('pending_review', 'flagged');

notify pgrst, 'reload schema';
