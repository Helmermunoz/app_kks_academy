-- Apply once, after migrations 001–004.
begin;
create function public.can_access_session(target uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.workouts w where w.id = target and
    ((w.athlete_id = auth.uid() and public.academy_role() = 'athlete')
      or public.can_manage_athlete(w.athlete_id)))
$$;
create function public.can_review_video(target uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.session_videos v join public.workouts w on w.id = v.workout_id
    where v.id = target and public.can_manage_athlete(w.athlete_id))
$$;
revoke all on function public.can_access_session(uuid), public.can_review_video(uuid) from public, anon;
grant execute on function public.can_access_session(uuid), public.can_review_video(uuid) to authenticated;

create table public.session_reports (
  workout_id uuid primary key references public.workouts(id) on delete cascade,
  planned_pitches integer check (planned_pitches between 0 and 500),
  actual_pitches integer check (actual_pitches between 0 and 500),
  strikes integer check (strikes is null or (actual_pitches is not null and strikes between 0 and actual_pitches)),
  velocity_mph numeric check (velocity_mph > 0 and velocity_mph <= 120),
  pitch_types text not null default '' check (length(pitch_types) <= 500),
  effort integer not null check (effort between 1 and 10),
  discomfort boolean not null default false,
  notes text not null default '' check (length(notes) <= 2000),
  updated_by uuid not null default auth.uid() references public.profiles(id),
  updated_at timestamptz not null default now(),
  check (not discomfort or length(trim(notes)) > 0)
);
create table public.video_reviews (
  video_id uuid primary key references public.session_videos(id) on delete cascade,
  status text not null check (status in ('reviewed','work_on')),
  notes text not null default '' check (length(notes) <= 2000),
  at_seconds integer check (at_seconds between 0 and 86400),
  reviewed_by uuid not null default auth.uid() references public.profiles(id),
  reviewed_at timestamptz not null default now(),
  check (status <> 'work_on' or length(trim(notes)) > 0)
);
-- Attribution/timestamps cannot be supplied by the browser or preserved by another editor.
create function public.stamp_development() returns trigger
language plpgsql set search_path = '' as $$
begin
  if tg_table_name = 'session_reports' then
    new.updated_by := auth.uid(); new.updated_at := now();
  else
    new.reviewed_by := auth.uid(); new.reviewed_at := now();
  end if;
  return new;
end $$;
revoke all on function public.stamp_development() from public, anon, authenticated;
create trigger stamp_session_report before insert or update on public.session_reports
for each row execute function public.stamp_development();
create trigger stamp_video_review before insert or update on public.video_reviews
for each row execute function public.stamp_development();
alter table public.session_reports enable row level security;
alter table public.video_reviews enable row level security;
revoke all on public.session_reports, public.video_reviews from anon, authenticated;
grant select, insert on public.session_reports, public.video_reviews to authenticated;
grant update(planned_pitches, actual_pitches, strikes, velocity_mph, pitch_types, effort, discomfort, notes)
  on public.session_reports to authenticated;
grant update(status, notes, at_seconds) on public.video_reviews to authenticated;
create policy reports_read on public.session_reports for select to authenticated
using (public.can_access_session(workout_id));
create policy reports_add on public.session_reports for insert to authenticated
with check (public.can_access_session(workout_id));
create policy reports_edit on public.session_reports for update to authenticated
using (public.can_access_session(workout_id)) with check (public.can_access_session(workout_id));
-- The community can watch clips; feedback and health details stay with the athlete and their staff.
create policy reviews_read on public.video_reviews for select to authenticated
using (exists(select 1 from public.session_videos v where v.id = video_id
  and public.can_access_session(v.workout_id)));
create policy reviews_add on public.video_reviews for insert to authenticated
with check (public.can_review_video(video_id));
create policy reviews_edit on public.video_reviews for update to authenticated
using (public.can_review_video(video_id)) with check (public.can_review_video(video_id));
commit;
