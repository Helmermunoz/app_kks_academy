-- Run after the migration on a TEST Supabase project, using SQL Editor as postgres.
-- Everything is rolled back. Any failed assertion stops the test.
begin;
create function pg_temp.check_access(ok boolean, description text) returns void
language plpgsql as $$ begin
  if ok is distinct from true then raise exception 'FAILED: %', description; end if;
end $$;
select pg_temp.check_access(
  has_schema_privilege('service_role', 'public', 'USAGE')
  and has_table_privilege('service_role', 'public.profiles', 'SELECT'),
  'account creation server can read caller profile');
select pg_temp.check_access(
  has_table_privilege('service_role', 'public.profiles', 'INSERT'),
  'account creation server can insert profile');

insert into auth.users(id, email) values
('00000000-0000-0000-0000-000000000001', 'admin@rls.example'),
('00000000-0000-0000-0000-000000000002', 'coach@rls.example'),
('00000000-0000-0000-0000-000000000003', 'a@rls.example'),
('00000000-0000-0000-0000-000000000004', 'b@rls.example'),
('00000000-0000-0000-0000-000000000005', 'unassigned@rls.example');
insert into public.profiles(id, name, role, must_change_password) values
('00000000-0000-0000-0000-000000000001','Admin','admin',false),
('00000000-0000-0000-0000-000000000002','Coach','coach',false),
('00000000-0000-0000-0000-000000000003','Athlete A','athlete',false),
('00000000-0000-0000-0000-000000000004','Athlete B','athlete',false),
('00000000-0000-0000-0000-000000000005','Unassigned coach','coach',false);

set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',true);
insert into public.coach_athletes values
('00000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000003');
insert into public.workouts(id, athlete_id, day, title, instructions) values
('10000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000003','2026-09-23','A plan','A exercises'),
('10000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000004','2026-09-23','B plan','B exercises');
select pg_temp.check_access((select count(*) = 2 from public.workouts where id::text like '10000000-%'), 'admin can create and read both plans');

select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000003',true);
select pg_temp.check_access((select count(*) = 1 from public.workouts), 'athlete sees only own plan');
select pg_temp.check_access((select count(*) = 1 from public.profiles), 'athlete sees only own profile');
do $$ begin
  update public.profiles set role = 'admin' where id = auth.uid();
  raise exception 'FAILED: athlete promoted self';
exception when insufficient_privilege then null; end $$;
do $$ begin
  insert into public.workouts(athlete_id, day, title, instructions)
  values(auth.uid(), current_date, 'Unauthorized', 'Unauthorized');
  raise exception 'FAILED: athlete created workout';
exception when insufficient_privilege then null; end $$;
update public.workouts set title = 'Tampered' where id = '10000000-0000-0000-0000-000000000001';
select pg_temp.check_access((select title = 'A plan' from public.workouts where id = '10000000-0000-0000-0000-000000000001'), 'athlete cannot edit plan');
insert into public.workout_completions(workout_id) values ('10000000-0000-0000-0000-000000000001');
select pg_temp.check_access((select count(*) = 1 from public.workout_completions), 'athlete can complete own plan');
do $$ begin
  insert into public.workout_completions(workout_id) values ('10000000-0000-0000-0000-000000000002');
  raise exception 'FAILED: athlete completed another plan';
exception when insufficient_privilege then null; end $$;

select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000004',true);
select pg_temp.check_access((select count(*) = 0 from public.workout_completions), 'other athlete cannot see completion');

select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000002',true);
select pg_temp.check_access((select count(*) = 1 from public.workouts), 'coach sees only assigned plan');
select pg_temp.check_access((select count(*) = 1 from public.workout_completions), 'coach can see assigned progress');
update public.workouts set instructions = 'Updated by coach' where id = '10000000-0000-0000-0000-000000000001';
select pg_temp.check_access((select instructions = 'Updated by coach' from public.workouts where id = '10000000-0000-0000-0000-000000000001'), 'coach can edit assigned plan');
do $$ begin
  insert into public.workouts(athlete_id, day, title, instructions)
  values('00000000-0000-0000-0000-000000000004',current_date,'Unauthorized','Unauthorized');
  raise exception 'FAILED: coach created unassigned plan';
exception when insufficient_privilege then null; end $$;
do $$ begin
  update public.workouts set athlete_id = '00000000-0000-0000-0000-000000000004'
  where id = '10000000-0000-0000-0000-000000000001';
  raise exception 'FAILED: coach reassigned plan';
exception when insufficient_privilege then null; end $$;
do $$ begin
  insert into public.coach_athletes values(auth.uid(),'00000000-0000-0000-0000-000000000004');
  raise exception 'FAILED: coach assigned self';
exception when insufficient_privilege then null; end $$;

select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000005',true);
select pg_temp.check_access((select count(*) = 0 from public.workouts), 'unassigned coach sees no plans');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',true);
delete from public.coach_athletes where coach_id = '00000000-0000-0000-0000-000000000002';
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000002',true);
select pg_temp.check_access((select count(*) = 0 from public.workouts), 'revoked coach loses access');

reset role;
update public.profiles set must_change_password = true where id = '00000000-0000-0000-0000-000000000003';
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000003',true);
select pg_temp.check_access((select count(*) = 0 from public.workouts), 'temporary password blocks plans');
reset role;
update auth.users set encrypted_password = 'test-only-hash' where id = '00000000-0000-0000-0000-000000000003';
select pg_temp.check_access((select not must_change_password from public.profiles where id = '00000000-0000-0000-0000-000000000003'), 'auth password update clears temporary flag');
set local role anon;
do $$ begin
  perform * from public.workouts;
  raise exception 'FAILED: anonymous access';
exception when insufficient_privilege then null; end $$;
reset role;
rollback;
