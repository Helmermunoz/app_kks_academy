-- Run ONLY in a test project after migration 005. All fixture data is rolled back.
begin;
insert into auth.users(id,email) values
('50000000-0000-0000-0000-000000000001','a@development.example'),
('50000000-0000-0000-0000-000000000002','b@development.example'),
('50000000-0000-0000-0000-000000000003','coach@development.example');
insert into public.profiles(id,name,role,must_change_password) values
('50000000-0000-0000-0000-000000000001','A','athlete',false),
('50000000-0000-0000-0000-000000000002','B','athlete',false),
('50000000-0000-0000-0000-000000000003','Coach','coach',false);
insert into public.coach_athletes values
('50000000-0000-0000-0000-000000000003','50000000-0000-0000-0000-000000000001');
insert into public.workouts(id,athlete_id,day,title,instructions,kind,created_by) values
('50000000-0000-0000-0000-000000000004','50000000-0000-0000-0000-000000000001',current_date,'Bullpen','20 rectas','bullpen','50000000-0000-0000-0000-000000000003');
-- Video fixture without a real storage upload. Restored before role checks.
alter table public.session_videos disable trigger session_video_details;
insert into public.session_videos(id,workout_id,uploaded_by,object_path,title,athlete_name,day,kind) values
('50000000-0000-0000-0000-000000000005','50000000-0000-0000-0000-000000000004','50000000-0000-0000-0000-000000000001','development-fixture.mp4','Clip','A',current_date,'bullpen');
alter table public.session_videos enable trigger session_video_details;
set local role authenticated;
select set_config('request.jwt.claim.sub','50000000-0000-0000-0000-000000000001',true);
insert into public.session_reports(workout_id,actual_pitches,strikes,effort) values
('50000000-0000-0000-0000-000000000004',20,15,7);
do $$ begin
  update public.session_reports set strikes = 21 where workout_id = '50000000-0000-0000-0000-000000000004';
  raise exception 'Invalid strikes accepted';
exception when check_violation then null; end $$;
-- Optional counts must allow non-throwing sessions, but a strike count requires a total.
update public.session_reports set actual_pitches = null, strikes = null where workout_id = '50000000-0000-0000-0000-000000000004';
do $$ begin
  update public.session_reports set strikes = 1 where workout_id = '50000000-0000-0000-0000-000000000004';
  raise exception 'Strikes accepted without a total';
exception when check_violation then null; end $$;
update public.session_reports set actual_pitches = 20, strikes = 15 where workout_id = '50000000-0000-0000-0000-000000000004';
do $$ begin
  insert into public.video_reviews(video_id,status) values('50000000-0000-0000-0000-000000000005','reviewed');
  raise exception 'Athlete reviewed own video';
exception when insufficient_privilege then null; end $$;
select set_config('request.jwt.claim.sub','50000000-0000-0000-0000-000000000003',true);
insert into public.video_reviews(video_id,status,notes,at_seconds) values
('50000000-0000-0000-0000-000000000005','work_on','Revisar apoyo',12);
update public.session_reports set notes = 'Coach update' where workout_id = '50000000-0000-0000-0000-000000000004';
do $$ begin
  if not exists(select 1 from public.session_reports where workout_id = '50000000-0000-0000-0000-000000000004' and updated_by = auth.uid()) then raise exception 'Coach attribution missing'; end if;
end $$;
select set_config('request.jwt.claim.sub','50000000-0000-0000-0000-000000000002',true);
do $$ begin
  if exists(select 1 from public.session_reports where workout_id = '50000000-0000-0000-0000-000000000004') then raise exception 'Other athlete sees report'; end if;
  if exists(select 1 from public.video_reviews where video_id = '50000000-0000-0000-0000-000000000005') then raise exception 'Other athlete sees review'; end if;
  if not exists(select 1 from public.session_videos where id = '50000000-0000-0000-0000-000000000005') then raise exception 'Community clip no longer visible'; end if;
end $$;
do $$ begin
  insert into public.video_reviews(video_id,status) values('50000000-0000-0000-0000-000000000005','reviewed');
  raise exception 'Other athlete wrote review';
exception when insufficient_privilege then null; end $$;
select set_config('request.jwt.claim.sub','50000000-0000-0000-0000-000000000001',true);
do $$ begin
  if not exists(select 1 from public.video_reviews where video_id = '50000000-0000-0000-0000-000000000005') then raise exception 'Owner cannot read review'; end if;
  update public.video_reviews set notes = 'forged' where video_id = '50000000-0000-0000-0000-000000000005';
  if found then raise exception 'Athlete changed review'; end if;
end $$;
reset role;
delete from public.coach_athletes where coach_id = '50000000-0000-0000-0000-000000000003';
set local role authenticated;
select set_config('request.jwt.claim.sub','50000000-0000-0000-0000-000000000003',true);
do $$ begin
  if exists(select 1 from public.session_reports where workout_id = '50000000-0000-0000-0000-000000000004') then raise exception 'Revoked coach retains reports'; end if;
  if exists(select 1 from public.video_reviews where video_id = '50000000-0000-0000-0000-000000000005') then raise exception 'Revoked coach retains reviews'; end if;
end $$;
reset role;
set local role anon;
do $$ begin
  perform 1 from public.session_reports;
  raise exception 'Anonymous report access';
exception when insufficient_privilege then null; end $$;
reset role;
rollback;
