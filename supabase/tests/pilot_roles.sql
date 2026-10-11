begin;
create function pg_temp.assert_pilot(ok boolean) returns void language plpgsql as $$
begin if ok is distinct from true then raise exception 'Pilot permission assertion failed'; end if; end $$;
insert into auth.users(id,email) values
('90000000-0000-0000-0000-000000000001','viewer@pilot.example'),
('90000000-0000-0000-0000-000000000002','nutrition@pilot.example'),
('90000000-0000-0000-0000-000000000003','athlete@pilot.example');
insert into public.profiles(id,name,role,must_change_password) values
('90000000-0000-0000-0000-000000000001','Viewer','viewer',false),
('90000000-0000-0000-0000-000000000002','Nutrition','nutrition',false),
('90000000-0000-0000-0000-000000000003','Athlete','athlete',false);
insert into public.workouts(id,athlete_id,day,title,instructions,created_by) values
('91000000-0000-0000-0000-000000000001','90000000-0000-0000-0000-000000000003',current_date,'Original','Plan','90000000-0000-0000-0000-000000000001');
insert into public.nutrition_profiles(athlete_id,preferences) values
('90000000-0000-0000-0000-000000000003','Original');
set local role authenticated;
select set_config('request.jwt.claim.sub','90000000-0000-0000-0000-000000000001',true);
select pg_temp.assert_pilot((select count(*)=1 from public.workouts));
update public.workouts set title='Forbidden';
select pg_temp.assert_pilot((select title='Original' from public.workouts));
update public.nutrition_profiles set preferences='Forbidden';
select pg_temp.assert_pilot((select preferences='Original' from public.nutrition_profiles));
do $$ begin
 insert into public.workouts(athlete_id,day,title,instructions) values
 ('90000000-0000-0000-0000-000000000003',current_date,'Forbidden','Forbidden');
 raise exception 'Viewer could create workout';
exception when insufficient_privilege then null; end $$;
delete from public.workouts;
select pg_temp.assert_pilot((select count(*)=1 from public.workouts));
select set_config('request.jwt.claim.sub','90000000-0000-0000-0000-000000000002',true);
select pg_temp.assert_pilot((select count(*)=0 from public.workouts));
update public.nutrition_profiles set preferences='Nutrition edited';
select pg_temp.assert_pilot((select preferences='Nutrition edited' from public.nutrition_profiles));
select pg_temp.assert_pilot(not public.can_manage_athlete('90000000-0000-0000-0000-000000000003'));
do $$ begin
 update public.profiles set role='admin' where id=auth.uid();
 raise exception 'Nutrition promoted self';
exception when insufficient_privilege then null; end $$;
reset role;
rollback;
