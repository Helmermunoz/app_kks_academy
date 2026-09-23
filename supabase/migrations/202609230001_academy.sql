-- One academy per Supabase project. Apply once before creating accounts.
begin;
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null check (length(trim(name)) between 1 and 100),
  role text not null default 'athlete' check (role in ('admin','coach','athlete')),
  must_change_password boolean not null default true
);
create table public.coach_athletes (
  coach_id uuid not null references public.profiles(id) on delete cascade,
  athlete_id uuid not null references public.profiles(id) on delete cascade,
  primary key (coach_id, athlete_id),
  check (coach_id <> athlete_id)
);
create table public.workouts (
  id uuid primary key default gen_random_uuid(),
  athlete_id uuid not null references public.profiles(id) on delete cascade,
  day date not null,
  title text not null check (length(trim(title)) between 1 and 150),
  instructions text not null check (length(trim(instructions)) between 1 and 10000),
  created_by uuid not null default auth.uid() references public.profiles(id),
  created_at timestamptz not null default now()
);
create index on public.workouts(athlete_id, day);
create table public.workout_completions (
  workout_id uuid primary key references public.workouts(id) on delete cascade,
  athlete_id uuid not null default auth.uid() references public.profiles(id),
  completed_at timestamptz not null default now()
);

create function public.academy_role() returns text
language sql stable security definer set search_path = '' as $$
  select role from public.profiles where id = auth.uid() and not must_change_password
$$;
create function public.can_manage_athlete(target uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.profiles where id = target and role = 'athlete')
    and (public.academy_role() = 'admin' or
      (public.academy_role() = 'coach' and exists(
        select 1 from public.coach_athletes
        where coach_id = auth.uid() and athlete_id = target)))
$$;
revoke all on function public.academy_role() from public, anon;
revoke all on function public.can_manage_athlete(uuid) from public, anon;
grant execute on function public.academy_role(), public.can_manage_athlete(uuid) to authenticated;

alter table public.profiles enable row level security;
alter table public.coach_athletes enable row level security;
alter table public.workouts enable row level security;
alter table public.workout_completions enable row level security;
revoke all on public.profiles, public.coach_athletes, public.workouts, public.workout_completions from anon, authenticated;
grant select on public.profiles to authenticated;
grant select, insert, delete on public.coach_athletes to authenticated;
grant select, insert, delete on public.workouts to authenticated;
grant update(title, instructions, day) on public.workouts to authenticated;
grant select, insert, delete on public.workout_completions to authenticated;

create policy profiles_read on public.profiles for select to authenticated
using (id = auth.uid() or public.academy_role() = 'admin' or public.can_manage_athlete(id));
create policy assignments_read on public.coach_athletes for select to authenticated
using (public.academy_role() = 'admin' or coach_id = auth.uid());
create policy assignments_add on public.coach_athletes for insert to authenticated
with check (public.academy_role() = 'admin'
  and exists(select 1 from public.profiles where id = coach_id and role = 'coach')
  and exists(select 1 from public.profiles where id = athlete_id and role = 'athlete'));
create policy assignments_remove on public.coach_athletes for delete to authenticated
using (public.academy_role() = 'admin');
create policy workouts_read on public.workouts for select to authenticated
using ((athlete_id = auth.uid() and public.academy_role() = 'athlete') or public.can_manage_athlete(athlete_id));
create policy workouts_add on public.workouts for insert to authenticated
with check (public.can_manage_athlete(athlete_id) and created_by = auth.uid());
create policy workouts_edit on public.workouts for update to authenticated
using (public.can_manage_athlete(athlete_id))
with check (public.can_manage_athlete(athlete_id));
create policy workouts_remove on public.workouts for delete to authenticated
using (public.can_manage_athlete(athlete_id));
create policy completions_read on public.workout_completions for select to authenticated
using ((athlete_id = auth.uid() and public.academy_role() = 'athlete') or public.can_manage_athlete(athlete_id));
create policy completions_add on public.workout_completions for insert to authenticated
with check (athlete_id = auth.uid() and public.academy_role() = 'athlete'
  and exists(select 1 from public.workouts where id = workout_id and athlete_id = auth.uid()));
create policy completions_remove on public.workout_completions for delete to authenticated
using (athlete_id = auth.uid() and public.academy_role() = 'athlete');

-- Mark the temporary password as changed only when Auth actually changes its hash.
create function public.academy_password_changed() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.encrypted_password is distinct from old.encrypted_password then
    update public.profiles set must_change_password = false where id = new.id;
  end if;
  return new;
end $$;
revoke all on function public.academy_password_changed() from public, anon, authenticated;
create trigger academy_password_changed after update of encrypted_password on auth.users
for each row execute function public.academy_password_changed();
commit;
