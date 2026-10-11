begin;
alter table public.profiles drop constraint profiles_role_check;
alter table public.profiles add constraint profiles_role_check
  check(role in ('admin','coach','athlete','viewer','nutrition'));
alter table public.profiles add column username text unique
  check(username ~ '^[a-z0-9][a-z0-9._-]{2,31}$');
alter table public.profiles add column position text
  check(position in ('pitcher','catcher'));
alter policy videos_read on public.session_videos using
  (public.academy_role() in ('admin','coach','athlete','viewer'));
alter policy session_files_read on storage.objects using
  (bucket_id='session-videos' and public.academy_role() in ('admin','coach','athlete','viewer')
   and (split_part(name,'/',1)=auth.uid()::text
    or exists(select 1 from public.session_videos v where v.object_path=name)));

-- Consultation never enters can_manage_athlete: write policies stay unchanged.
create policy profiles_consultation on public.profiles for select to authenticated
using(public.academy_role()='viewer' or
  (public.academy_role()='nutrition' and role='athlete'));
create policy assignments_consultation on public.coach_athletes for select to authenticated
using(public.academy_role()='viewer');
create policy workouts_consultation on public.workouts for select to authenticated
using(public.academy_role()='viewer');
create policy completions_consultation on public.workout_completions for select to authenticated
using(public.academy_role()='viewer');
create policy videos_consultation on public.session_videos for select to authenticated
using(public.academy_role()='viewer');
create policy reports_consultation on public.session_reports for select to authenticated
using(public.academy_role()='viewer');
create policy reviews_consultation on public.video_reviews for select to authenticated
using(public.academy_role()='viewer');
create policy nutrition_consultation on public.nutrition_profiles for select to authenticated
using(public.academy_role()='viewer');
create policy inbody_consultation on public.inbody_measurements for select to authenticated
using(public.academy_role()='viewer');

create or replace function public.can_access_nutrition(target uuid) returns boolean
language sql stable security definer set search_path='' as $$
  select (target=auth.uid() and public.academy_role()='athlete')
    or public.can_manage_athlete(target)
    or (public.academy_role()='nutrition' and exists(
      select 1 from public.profiles where id=target and role='athlete'))
$$;
-- Username/position/role remain writable only from the server/owner.
commit;
