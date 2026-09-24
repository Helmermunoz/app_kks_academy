begin;
create function public.can_access_nutrition(target uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select (target = auth.uid() and public.academy_role() = 'athlete')
    or public.can_manage_athlete(target)
$$;
revoke all on function public.can_access_nutrition(uuid) from public, anon;
grant execute on function public.can_access_nutrition(uuid) to authenticated;

create table public.nutrition_profiles (
  athlete_id uuid primary key references public.profiles(id) on delete cascade,
  birth_date date check (birth_date between date '1900-01-01' and current_date),
  goals text not null default '' check(length(goals) <= 2000),
  allergies text not null default '' check(length(allergies) <= 2000),
  preferences text not null default '' check(length(preferences) <= 2000),
  budget text not null default '' check(length(budget) <= 300)
);
create table public.inbody_measurements (
  id uuid primary key default gen_random_uuid(),
  athlete_id uuid not null references public.profiles(id) on delete cascade,
  measured_on date not null check(measured_on between date '1900-01-01' and current_date),
  height_cm numeric check(height_cm > 0 and height_cm <= 300),
  weight_kg numeric not null check(weight_kg > 0 and weight_kg <= 500),
  body_fat_percent numeric check(body_fat_percent >= 0 and body_fat_percent <= 100),
  fat_mass_kg numeric check(fat_mass_kg >= 0 and fat_mass_kg <= weight_kg),
  skeletal_muscle_kg numeric check(skeletal_muscle_kg >= 0 and skeletal_muscle_kg <= weight_kg),
  basal_kcal numeric check(basal_kcal > 0 and basal_kcal <= 10000),
  notes text not null default '' check(length(notes) <= 3000),
  created_by uuid not null default auth.uid() references public.profiles(id),
  created_at timestamptz not null default now()
);
create index on public.inbody_measurements(athlete_id, measured_on desc, created_at desc);
alter table public.nutrition_profiles enable row level security;
alter table public.inbody_measurements enable row level security;
revoke all on public.nutrition_profiles, public.inbody_measurements from anon, authenticated;
grant select, insert on public.nutrition_profiles, public.inbody_measurements to authenticated;
grant update(birth_date, goals, allergies, preferences, budget) on public.nutrition_profiles to authenticated;
create policy nutrition_read on public.nutrition_profiles for select to authenticated
using(public.can_access_nutrition(athlete_id));
create policy nutrition_add on public.nutrition_profiles for insert to authenticated
with check(public.can_access_nutrition(athlete_id));
create policy nutrition_edit on public.nutrition_profiles for update to authenticated
using(public.can_access_nutrition(athlete_id)) with check(public.can_access_nutrition(athlete_id));
create policy inbody_read on public.inbody_measurements for select to authenticated
using(public.can_access_nutrition(athlete_id));
create policy inbody_add on public.inbody_measurements for insert to authenticated
with check(public.can_access_nutrition(athlete_id) and created_by = auth.uid());
commit;
