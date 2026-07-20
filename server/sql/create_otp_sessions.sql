-- Audit trail for moderator/administrator decisions: alert verification
-- reviews and role/verification approvals. Kept separate from the generic
-- incident_logs table because moderation_actions also covers user-role
-- decisions that are not tied to any single alert.

create table if not exists public.moderation_actions (
  id uuid primary key default gen_random_uuid(),
  alert_id uuid references public.alerts(id) on delete set null,
  target_user_id uuid references public.users(id) on delete set null,
  action_type text not null,
  performed_by uuid references public.users(id) on delete set null,
  notes text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc'::text, now())
);

alter table public.moderation_actions drop constraint if exists moderation_actions_action_type_check;
alter table public.moderation_actions add constraint moderation_actions_action_type_check check (
  action_type in (
    'alert_verified',
    'alert_disputed_reviewed',
    'alert_marked_false',
    'alert_resolved_by_moderator',
    'alert_visibility_restricted',
    'role_approved',
    'role_rejected',
    'role_suspended',
    'account_suspended',
    'other'
  )
);

create index if not exists moderation_actions_alert_id_idx on public.moderation_actions (alert_id);
create index if not exists moderation_actions_target_user_id_idx on public.moderation_actions (target_user_id);
create index if not exists moderation_actions_performed_by_idx on public.moderation_actions (performed_by);
create index if not exists moderation_actions_created_at_idx on public.moderation_actions (created_at desc);

notify pgrst, 'reload schema';
