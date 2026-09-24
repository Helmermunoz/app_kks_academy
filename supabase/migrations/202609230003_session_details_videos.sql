begin;
alter table public.workouts
  add column kind text not null default 'training' check (kind in ('training','bullpen','track','therapy')),
  add column location text not null default '' check (length(location) <= 300),
  add column start_time time,
  add column throwing_plan text not null default '' check (length(throwing_plan) <= 5000);
grant update(kind, location, start_time, throwing_plan) on public.workouts to authenticated;

create table public.session_videos (
  id uuid primary key default gen_random_uuid(),
  workout_id uuid not null references public.workouts(id) on delete cascade,
  uploaded_by uuid not null default auth.uid() references public.profiles(id),
  object_path text not null unique,
  title text not null check (length(trim(title)) between 1 and 150),
  athlete_name text not null,
  day date not null,
  kind text not null check (kind in ('training','bullpen','track')),
  created_at timestamptz not null default now()
);
create index on public.session_videos(workout_id, created_at);
alter table public.session_videos enable row level security;
revoke all on public.session_videos from anon, authenticated;
grant select, insert on public.session_videos to authenticated;

create function public.can_upload_session(target text) returns boolean
language sql stable security definer set search_path = '' as $$
  select public.academy_role() is not null and exists (
    select 1 from public.workouts w where w.id::text = target and w.kind <> 'therapy'
    and (w.athlete_id = auth.uid() or public.can_manage_athlete(w.athlete_id)))
$$;
revoke all on function public.can_upload_session(text) from public, anon;
grant execute on function public.can_upload_session(text) to authenticated;

-- Only these public-to-members details are copied; private instructions and location stay private.
create function public.session_video_details() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.uploaded_by <> auth.uid() or not public.can_upload_session(new.workout_id::text) then
    raise exception 'Not authorized' using errcode = '42501';
  end if;
  if split_part(new.object_path, '/', 1) <> auth.uid()::text
     or split_part(new.object_path, '/', 2) <> new.workout_id::text
     or not exists(select 1 from storage.objects where bucket_id = 'session-videos' and name = new.object_path) then
    raise exception 'Invalid uploaded object' using errcode = '42501';
  end if;
  select p.name, w.day, w.kind into new.athlete_name, new.day, new.kind
    from public.workouts w join public.profiles p on p.id = w.athlete_id where w.id = new.workout_id;
  return new;
end $$;
revoke all on function public.session_video_details() from public, anon, authenticated;
create trigger session_video_details before insert on public.session_videos
for each row execute function public.session_video_details();
create policy videos_read on public.session_videos for select to authenticated
using (public.academy_role() is not null);
create policy videos_add on public.session_videos for insert to authenticated
with check (uploaded_by = auth.uid() and public.can_upload_session(workout_id::text));

insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
values ('session-videos', 'session-videos', false, 52428800, array['video/mp4','video/webm','video/quicktime']);
create policy session_files_add on storage.objects for insert to authenticated
with check (bucket_id = 'session-videos' and split_part(name, '/', 1) = auth.uid()::text
  and public.can_upload_session(split_part(name, '/', 2)));
create policy session_files_read on storage.objects for select to authenticated
using (bucket_id = 'session-videos' and public.academy_role() is not null
  and (split_part(name, '/', 1) = auth.uid()::text
    or exists(select 1 from public.session_videos v where v.object_path = name)));
-- Allows cleanup of an upload if saving its metadata fails.
create policy session_files_cleanup on storage.objects for delete to authenticated
using (bucket_id = 'session-videos' and split_part(name, '/', 1) = auth.uid()::text
  and public.academy_role() is not null
  and not exists(select 1 from public.session_videos v where v.object_path = name));
commit;
