-- TEST PROJECT ONLY after 001–006. All fixtures rolled back. Does not call OpenAI.
begin;
create function pg_temp.check_nutrition(ok boolean, description text) returns void
language plpgsql as $$ begin
  if ok is distinct from true then raise exception 'FAILED: %',description; end if;
end $$;
insert into auth.users(id,email) values
 ('60000000-0000-0000-0000-000000000001','admin@proposal.example'),
 ('60000000-0000-0000-0000-000000000002','coach@proposal.example'),
 ('60000000-0000-0000-0000-000000000003','adult@proposal.example'),
 ('60000000-0000-0000-0000-000000000004','minor@proposal.example'),
 ('60000000-0000-0000-0000-000000000005','othercoach@proposal.example');
insert into public.profiles(id,name,role,must_change_password) values
 ('60000000-0000-0000-0000-000000000001','Admin','admin',false),
 ('60000000-0000-0000-0000-000000000002','Coach','coach',false),
 ('60000000-0000-0000-0000-000000000003','Adult','athlete',false),
 ('60000000-0000-0000-0000-000000000004','Minor','athlete',false),
 ('60000000-0000-0000-0000-000000000005','Other coach','coach',false);
insert into public.coach_athletes values
 ('60000000-0000-0000-0000-000000000002','60000000-0000-0000-0000-000000000003');
insert into public.nutrition_reviewers values
 ('60000000-0000-0000-0000-000000000002','Verified test professional');
insert into public.nutrition_profiles(athlete_id,birth_date,ai_consent_at) values
 ('60000000-0000-0000-0000-000000000003',current_date-interval '25 years',now()),
 ('60000000-0000-0000-0000-000000000004',current_date-interval '15 years',now());
set local role authenticated;
select set_config('request.jwt.claim.sub','60000000-0000-0000-0000-000000000002',true);
insert into public.workouts(id,athlete_id,day,title,instructions,start_time,duration_minutes,intensity,publication_status) values
 ('61000000-0000-0000-0000-000000000001','60000000-0000-0000-0000-000000000003',current_date,'Test','General mobility','16:00',45,'moderate','draft');
select pg_temp.check_nutrition((select count(*)=0 from public.nutrition_jobs),'draft does not queue');
update public.workouts set publication_status='published' where id='61000000-0000-0000-0000-000000000001';
select pg_temp.check_nutrition((select count(*)=1 from public.nutrition_jobs),'publish queues once');
update public.workouts set title=title where id='61000000-0000-0000-0000-000000000001';
select pg_temp.check_nutrition((select count(*)=1 from public.nutrition_jobs),'unchanged save does not queue');
select pg_temp.check_nutrition((select count(*)=1 from public.workout_versions),'prior draft retained');
select set_config('request.jwt.claim.sub','60000000-0000-0000-0000-000000000003',true);
select pg_temp.check_nutrition((select count(*)=0 from public.nutrition_jobs),'athlete cannot read queue');
do $$ begin
 update public.nutrition_profiles set ai_consent_at=now() where athlete_id=auth.uid();
 raise exception 'FAILED: athlete forged consent';
 exception when insufficient_privilege then null;
end $$;
do $$ begin
 insert into public.nutrition_profiles(athlete_id,ai_consent_at) values(auth.uid(),now());
 raise exception 'FAILED: athlete forged consent on insert';
 exception when insufficient_privilege then null;
end $$;
reset role;
-- Minors do not queue even when administrator has recorded consent.
select set_config('request.jwt.claim.sub','60000000-0000-0000-0000-000000000001',true);
insert into public.workouts(athlete_id,day,title,instructions,start_time,duration_minutes,intensity)
 values('60000000-0000-0000-0000-000000000004',current_date,'Minor test','General','16:00',45,'low');
select pg_temp.check_nutrition((select count(*)=1 from public.nutrition_jobs),'minor blocked');
do $$ declare j uuid; begin
 select id into j from public.nutrition_jobs limit 1;
 perform public.claim_nutrition_job(j,'60000000-0000-0000-0000-000000000005');
 raise exception 'FAILED: unassigned coach claimed job';
 exception when insufficient_privilege then null;
end $$;
select public.claim_nutrition_job(id,'60000000-0000-0000-0000-000000000002') from public.nutrition_jobs;
select pg_temp.check_nutrition((select count(*)=0 from public.claim_nutrition_job(
 (select id from public.nutrition_jobs limit 1),'60000000-0000-0000-0000-000000000002')),'active lease prevents duplicate');
select public.finish_nutrition_job(id,lease_token,
 '{"meals":[{"suggestion":"Example","timing":"General"}],"hydration":"General","recovery":"General","review_warning":"Review"}'::jsonb,
 'mock-v1','mock') from public.nutrition_jobs;
set local role authenticated;
select set_config('request.jwt.claim.sub','60000000-0000-0000-0000-000000000003',true);
select pg_temp.check_nutrition((select count(*)=0 from public.nutrition_proposals),'draft invisible to athlete');
select set_config('request.jwt.claim.sub','60000000-0000-0000-0000-000000000002',true);
do $$ begin
 perform public.review_nutrition_proposal((select id from public.nutrition_proposals limit 1),true,'Test review');
 raise exception 'FAILED: mock approved';
 exception when raise_exception then
   if sqlerrm <> 'Mock, stale or ineligible' then raise; end if;
end $$;
reset role;
-- Simulate a validated live output without calling the provider.
update public.nutrition_proposals set generation_mode='live';
set local role authenticated;
select set_config('request.jwt.claim.sub','60000000-0000-0000-0000-000000000002',true);
select public.review_nutrition_proposal(id,true,'Reviewed in test') from public.nutrition_proposals;
select set_config('request.jwt.claim.sub','60000000-0000-0000-0000-000000000003',true);
select pg_temp.check_nutrition((select count(*)=1 from public.nutrition_proposals),'approved current proposal visible');
update public.nutrition_profiles set allergies='Changed allergy' where athlete_id=auth.uid();
select pg_temp.check_nutrition((select count(*)=0 from public.nutrition_proposals),'changed allergy invalidates visibility');
select set_config('request.jwt.claim.sub','60000000-0000-0000-0000-000000000005',true);
select pg_temp.check_nutrition((select count(*)=0 from public.nutrition_proposals),'unassigned coach cannot read proposal');
rollback;
