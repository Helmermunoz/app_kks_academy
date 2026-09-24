-- Run on an empty TEST project after migrations 001, 002 and 003.
-- Storage object rows below simulate metadata only; no real files are uploaded.
begin;
create function pg_temp.verify(ok boolean, message text) returns void language plpgsql as $$
begin if ok is distinct from true then raise exception 'FAILED: %', message; end if; end $$;
insert into auth.users(id, email) values
('20000000-0000-0000-0000-000000000001','admin@video.example'),
('20000000-0000-0000-0000-000000000002','athlete@video.example'),
('20000000-0000-0000-0000-000000000003','other@video.example');
insert into public.profiles(id, name, role, must_change_password) values
('20000000-0000-0000-0000-000000000001','Admin','admin',false),
('20000000-0000-0000-0000-000000000002','Athlete','athlete',false),
('20000000-0000-0000-0000-000000000003','Other athlete','athlete',false);
set local role authenticated;
select set_config('request.jwt.claim.sub','20000000-0000-0000-0000-000000000001',true);
insert into public.workouts(id, athlete_id, day, title, instructions, kind, location, start_time, throwing_plan) values
('30000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000002',current_date,'Bullpen','Private instructions','bullpen','Private location','16:30','Private plan'),
('30000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000002',current_date,'Therapy','Private therapy','therapy','Clinic','17:30','');
update public.workouts set location = 'Field 2', start_time = '16:45', throwing_plan = 'Updated plan'
where id = '30000000-0000-0000-0000-000000000001';
select pg_temp.verify((select location = 'Field 2' and start_time = '16:45'::time and throwing_plan = 'Updated plan'
from public.workouts where id = '30000000-0000-0000-0000-000000000001'), 'staff can update new session fields');

select set_config('request.jwt.claim.sub','20000000-0000-0000-0000-000000000002',true);
select pg_temp.verify(public.can_upload_session('30000000-0000-0000-0000-000000000001'), 'athlete can upload to own session');
select pg_temp.verify(not public.can_upload_session('30000000-0000-0000-0000-000000000002'), 'therapy excluded from video sharing');
insert into storage.objects(bucket_id, name) values ('session-videos','20000000-0000-0000-0000-000000000002/30000000-0000-0000-0000-000000000001/clip.mp4');
insert into public.session_videos(workout_id, object_path, title) values
('30000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000002/30000000-0000-0000-0000-000000000001/clip.mp4','Practice');
select pg_temp.verify((select athlete_name = 'Athlete' and kind = 'bullpen' and day = current_date from public.session_videos), 'server supplies accurate shared metadata');

select set_config('request.jwt.claim.sub','20000000-0000-0000-0000-000000000003',true);
select pg_temp.verify((select count(*) = 0 from public.workouts), 'community viewer cannot read private workouts');
select pg_temp.verify((select count(*) = 1 from public.session_videos), 'member can read community video metadata');
select pg_temp.verify((select count(*) = 1 from storage.objects where bucket_id = 'session-videos'), 'member can access published clip');
select pg_temp.verify(not public.can_upload_session('30000000-0000-0000-0000-000000000001'), 'other athlete cannot upload to session');
do $$ begin
  insert into storage.objects(bucket_id, name) values ('session-videos','20000000-0000-0000-0000-000000000003/30000000-0000-0000-0000-000000000001/forged.mp4');
  raise exception 'FAILED: unauthorized upload';
exception when insufficient_privilege then null; end $$;
reset role;
set local role anon;
do $$ begin
  perform * from public.session_videos;
  raise exception 'FAILED: anonymous video access';
exception when insufficient_privilege then null; end $$;
reset role;
rollback;
