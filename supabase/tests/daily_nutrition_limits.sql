-- Isolated fixtures; no provider calls. All data rolls back.
begin;
create function pg_temp.daily_check(ok boolean, label text) returns void language plpgsql as $$
begin if ok is distinct from true then raise exception 'FAILED: %',label; end if; end $$;
insert into auth.users(id,email) values
 ('80000000-0000-0000-0000-000000000001','daily-admin@example.invalid'),
 ('80000000-0000-0000-0000-000000000002','daily-athlete@example.invalid'),
 ('80000000-0000-0000-0000-000000000003','daily-second@example.invalid');
insert into public.profiles(id,name,role,must_change_password,position) values
 ('80000000-0000-0000-0000-000000000001','Daily admin','admin',false,null),
 ('80000000-0000-0000-0000-000000000002','Daily athlete','athlete',false,'pitcher'),
 ('80000000-0000-0000-0000-000000000003','Second athlete','athlete',false,'catcher');
insert into public.nutrition_profiles(athlete_id,birth_date,ai_consent_at) values
 ('80000000-0000-0000-0000-000000000002',current_date-interval '25 years',now()),
 ('80000000-0000-0000-0000-000000000003',current_date-interval '25 years',now());
select set_config('request.jwt.claim.sub','80000000-0000-0000-0000-000000000001',true);
insert into public.workouts(id,athlete_id,day,title,instructions,kind,start_time,duration_minutes,intensity) values
 ('81000000-0000-0000-0000-000000000001','80000000-0000-0000-0000-000000000002',current_date,'Pitching','Throwing','bullpen','09:00',40,'moderate');
update public.workouts set title=title where id='81000000-0000-0000-0000-000000000001';
select pg_temp.daily_check((select count(*)=1 from public.nutrition_jobs),'unchanged save queues nothing');
insert into public.workouts(id,athlete_id,day,title,instructions,kind) values
 ('81000000-0000-0000-0000-000000000002','80000000-0000-0000-0000-000000000002',current_date,'Gym','Strength','training');
select pg_temp.daily_check(jsonb_array_length(public.nutrition_day_context('80000000-0000-0000-0000-000000000002',current_date)->'activities')=2,'both activities included even unknown schedule');
select pg_temp.daily_check((select count(*)=0 from public.claim_nutrition_job(
 (select id from public.nutrition_jobs where workout_id='81000000-0000-0000-0000-000000000001'),
 '80000000-0000-0000-0000-000000000001')),'old daily context never spends a slot');
do $$ declare j public.nutrition_jobs; claimed public.nutrition_jobs; n integer;
begin
 select * into j from public.nutrition_jobs where workout_id='81000000-0000-0000-0000-000000000002';
 for n in 1..2 loop
   select * into claimed from public.claim_nutrition_job(j.id,'80000000-0000-0000-0000-000000000001');
   perform pg_temp.daily_check(claimed.id is not null,'failed retry admitted');
   perform public.finish_nutrition_job(claimed.id,claimed.lease_token,null,'test','live','provider_transient');
   update public.nutrition_jobs set available_at=now()-interval '1 minute' where id=j.id;
 end loop;
 update public.workouts set instructions='Changed gym' where id='81000000-0000-0000-0000-000000000002';
 select * into j from public.nutrition_jobs where workout_id='81000000-0000-0000-0000-000000000002' order by workout_version desc limit 1;
 select * into claimed from public.claim_nutrition_job(j.id,'80000000-0000-0000-0000-000000000001');
 perform pg_temp.daily_check(claimed.id is not null,'third slot after real edit admitted');
 perform public.finish_nutrition_job(claimed.id,claimed.lease_token,
   '{"meals":[],"hydration":"test","recovery":"test","review_warning":"test"}'::jsonb,'test','mock');
 update public.workouts set instructions='Fourth material save' where id='81000000-0000-0000-0000-000000000002';
 select * into j from public.nutrition_jobs where workout_id='81000000-0000-0000-0000-000000000002' order by workout_version desc limit 1;
 select * into claimed from public.claim_nutrition_job(j.id,'80000000-0000-0000-0000-000000000001');
 perform pg_temp.daily_check(claimed.id is null,'fourth claim blocked across versions');
end $$;
select pg_temp.daily_check((select count(*)=3 from public.nutrition_attempts),'failures and retries consume persistent slots');
-- Deleting a source cannot erase the budget ledger.
delete from public.workouts where id='81000000-0000-0000-0000-000000000002';
select pg_temp.daily_check((select count(*)=3 from public.nutrition_attempts),'delete cannot reset cost limit');
insert into public.workouts(id,athlete_id,day,title,instructions,kind) values
 ('81000000-0000-0000-0000-000000000003','80000000-0000-0000-0000-000000000003',current_date,'Recovery','Rest','therapy');
select pg_temp.daily_check((select count(*)=1 from public.claim_nutrition_job(
 (select id from public.nutrition_jobs where workout_id='81000000-0000-0000-0000-000000000003'),
 '80000000-0000-0000-0000-000000000001')),'separate athlete has separate budget and therapy included');
select public.finish_nutrition_job(id,lease_token,
 '{"meals":[],"hydration":"test","recovery":"test","review_warning":"test"}'::jsonb,'test','live')
 from public.nutrition_jobs where status='running';
insert into public.nutrition_reviewers values('80000000-0000-0000-0000-000000000001','Test qualification');
set local role authenticated;
select public.review_nutrition_proposal(id,true,'Test review') from public.nutrition_proposals;
select set_config('request.jwt.claim.sub','80000000-0000-0000-0000-000000000003',true);
select pg_temp.daily_check((select count(*)=1 from public.nutrition_proposals),'current approved daily proposal visible');
reset role;
update public.workouts set instructions='Changed recovery' where id='81000000-0000-0000-0000-000000000003';
set local role authenticated;
select pg_temp.daily_check((select count(*)=0 from public.nutrition_proposals),'another material change hides stale proposal');
do $$ begin
 delete from public.nutrition_attempts;
 raise exception 'FAILED: client erased budget';
exception when insufficient_privilege then null; end $$;
do $$ begin
 perform public.claim_nutrition_job_v1(null,null);
 raise exception 'FAILED: client bypassed wrapper';
exception when insufficient_privilege then null; end $$;
reset role;
rollback;
