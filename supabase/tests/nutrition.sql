-- Execute in a TEST project after migration 004. All fixture rows are rolled back.
begin;
insert into auth.users(id, email) values
('40000000-0000-0000-0000-000000000001','a@nutrition.example'),
('40000000-0000-0000-0000-000000000002','b@nutrition.example'),
('40000000-0000-0000-0000-000000000003','coach@nutrition.example');
insert into public.profiles(id, name, role, must_change_password) values
('40000000-0000-0000-0000-000000000001','A','athlete',false),
('40000000-0000-0000-0000-000000000002','B','athlete',false),
('40000000-0000-0000-0000-000000000003','Coach','coach',false);
insert into public.coach_athletes values ('40000000-0000-0000-0000-000000000003','40000000-0000-0000-0000-000000000001');
set local role authenticated;
select set_config('request.jwt.claim.sub','40000000-0000-0000-0000-000000000001',true);
insert into public.nutrition_profiles(athlete_id, goals) values(auth.uid(),'Training');
insert into public.inbody_measurements(athlete_id, measured_on, weight_kg, body_fat_percent)
values(auth.uid(), current_date, 80, 18), (auth.uid(), current_date, 81, 17);
do $$ begin
  if (select count(*) from public.inbody_measurements where athlete_id = auth.uid()) <> 2 then raise exception 'History lost'; end if;
end $$;
do $$ begin
  update public.inbody_measurements set weight_kg = 100 where athlete_id = auth.uid();
  raise exception 'History must be append-only';
exception when insufficient_privilege then null; end $$;
select set_config('request.jwt.claim.sub','40000000-0000-0000-0000-000000000002',true);
do $$ begin
  if exists(select 1 from public.inbody_measurements where athlete_id = '40000000-0000-0000-0000-000000000001') then raise exception 'Private history exposed'; end if;
  if exists(select 1 from public.nutrition_profiles where athlete_id = '40000000-0000-0000-0000-000000000001') then raise exception 'Private profile exposed'; end if;
end $$;
do $$ begin
  insert into public.inbody_measurements(athlete_id, measured_on, weight_kg) values('40000000-0000-0000-0000-000000000001', current_date, 80);
  raise exception 'Unauthorized measurement accepted';
exception when insufficient_privilege then null; end $$;
select set_config('request.jwt.claim.sub','40000000-0000-0000-0000-000000000003',true);
do $$ begin
  if (select count(*) from public.inbody_measurements where athlete_id = '40000000-0000-0000-0000-000000000001') <> 2 then raise exception 'Assigned coach cannot read'; end if;
end $$;
reset role;
delete from public.coach_athletes where coach_id = '40000000-0000-0000-0000-000000000003';
set local role authenticated;
do $$ begin
  if exists(select 1 from public.inbody_measurements where athlete_id = '40000000-0000-0000-0000-000000000001') then raise exception 'Revoked coach retains access'; end if;
end $$;
reset role;
rollback;
