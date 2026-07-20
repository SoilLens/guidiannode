-- Evidence attachments (photo/video/audio) for an alert. Files are uploaded
-- through the Node backend (service-role Supabase Storage client) and never
-- directly from the Flutter client, so mime/size validation happens
-- server-side before a row is written here.

create table if not exists public.alert_media (
  id uuid primary key default gen_random_uuid(),
  alert_id uuid not null references public.alerts(id) on delete cascade,
  uploaded_by uuid not null references public.users(id) on delete cascade,
  media_type text not null,
  storage_path text not null,
  public_url text,
  mime_type text not null,
  size_bytes integer not null,
  created_at timestamptz not null default timezone('utc'::text, now())
);

alter table public.alert_media drop constraint if exists alert_media_type_check;
alter table public.alert_media add constraint alert_media_type_check check (
  media_type in ('image', 'video', 'audio')
);

create index if not exists alert_media_alert_id_idx on public.alert_media (alert_id);

notify pgrst, 'reload schema';
