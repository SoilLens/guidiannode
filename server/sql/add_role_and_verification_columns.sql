-- Extends public.users with the community-helper / responder role and
-- verification workflow described in the GuardianNode AI role system.
-- Citizens and community helpers may self-select their role. Sensitive
-- responder roles (verified_responder, medical_responder, security_responder,
-- humanitarian_responder) and moderator/administrator require an
-- administrator to move verification_status to 'approved'.

do $$
begin
  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'users'
      and column_name = 'role'
  ) then
    alter table public.users add column role text not null default 'citizen';
  end if;
end $$;

alter table if exists public.users
  add column if not exists requested_role text;

alter table if exists public.users
  add column if not exists verification_status text not null default 'not_requested';

alter table if exists public.users
  add column if not exists verification_date timestamptz;

alter table if exists public.users
  add column if not exists verified_by uuid references public.users(id) on delete set null;

alter table if exists public.users
  add column if not exists assistance_capabilities text[] not null default '{}'::text[];

alter table if exists public.users
  add column if not exists availability_status text not null default 'offline';

alter table if exists public.users
  add column if not exists service_radius_meters integer;

alter table if exists public.users
  add column if not exists organisation text;

alter table if exists public.users
  add column if not exists verification_notes text;

alter table public.users drop constraint if exists users_role_check;
alter table public.users add constraint users_role_check check (
  role in (
    'citizen',
    'community_helper',
    'verified_responder',
    'medical_responder',
    'security_responder',
    'humanitarian_responder',
    'moderator',
    'administrator'
  )
);

alter table public.users drop constraint if exists users_requested_role_check;
alter table public.users add constraint users_requested_role_check check (
  requested_role is null or requested_role in (
    'citizen',
    'community_helper',
    'verified_responder',
    'medical_responder',
    'security_responder',
    'humanitarian_responder',
    'moderator',
    'administrator'
  )
);

alter table public.users drop constraint if exists users_verification_status_check;
alter table public.users add constraint users_verification_status_check check (
  verification_status in ('not_requested', 'pending', 'approved', 'rejected', 'suspended')
);

alter table public.users drop constraint if exists users_availability_status_check;
alter table public.users add constraint users_availability_status_check check (
  availability_status in ('available', 'busy', 'offline')
);

create index if not exists users_role_idx on public.users (role);
create index if not exists users_verification_status_idx on public.users (verification_status);
create index if not exists users_pending_role_requests_idx
  on public.users (requested_role, verification_status)
  where verification_status = 'pending';

notify pgrst, 'reload schema';
