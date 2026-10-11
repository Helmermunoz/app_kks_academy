-- Review and apply once ONLY after 001–005, first in a disposable staging project.
begin;
alter table public.workouts
  add column duration_minutes integer check (duration_minutes between 1 and 480),
  add column intensity text check (intensity in ('low','moderate','high')),
  add column publication_status text not null default 'published' check (publication_status in ('draft','published')),
  add column version integer not null default 1;
grant update(duration_minutes, intensity, publication_status) on public.workouts to authenticated;
alter policy workouts_read on public.workouts using (
  (athlete_id = auth.uid() and public.academy_role() = 'athlete' and publication_status = 'published')
  or public.can_manage_athlete(athlete_id));
create table public.workout_versions (
  workout_id uuid not null references public.workouts(id) on delete cascade,
  version integer not null,
  athlete_id uuid not null references public.profiles(id),
  snapshot jsonb not null,
  recorded_at timestamptz not null default now(),
  primary key (workout_id,version)
);
alter table public.workout_versions enable row level security;
revoke all on public.workout_versions from anon, authenticated;
grant select on public.workout_versions to authenticated;
create policy workout_versions_read on public.workout_versions for select to authenticated
  using (public.can_manage_athlete(athlete_id));
create function public.archive_workout_version() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.version <> old.version then
    insert into public.workout_versions(workout_id,version,athlete_id,snapshot)
      values(old.id,old.version,old.athlete_id,to_jsonb(old)) on conflict do nothing;
  end if;
  return new;
end $$;
create trigger archive_workout_version after update on public.workouts
  for each row execute function public.archive_workout_version();
alter table public.nutrition_profiles
  add column dietary_restrictions text not null default '' check (length(dietary_restrictions) <= 2000),
  add column revision integer not null default 1,
  -- Consent is recorded by an administrator after explicit athlete consent. Never browser-writable.
  add column ai_consent_at timestamptz,
  add column ai_consent_by uuid references public.profiles(id),
  add column ai_consent_reference text check (length(ai_consent_reference) between 1 and 300);
grant update(dietary_restrictions) on public.nutrition_profiles to authenticated;
-- Existing 004 table-wide INSERT would otherwise let clients fabricate consent/revision.
revoke insert on public.nutrition_profiles from authenticated;
grant insert(athlete_id,birth_date,goals,allergies,preferences,budget,dietary_restrictions)
  on public.nutrition_profiles to authenticated;

create table public.nutrition_reviewers (
  profile_id uuid primary key references public.profiles(id),
  qualification_reference text not null check (length(trim(qualification_reference)) between 1 and 300)
);
create table public.nutrition_jobs (
  id uuid primary key default gen_random_uuid(),
  workout_id uuid not null references public.workouts(id) on delete cascade,
  athlete_id uuid not null references public.profiles(id),
  workout_version integer not null,
  nutrition_revision integer not null,
  status text not null default 'pending' check (status in ('pending','running','succeeded','failed','skipped')),
  attempts integer not null default 0 check (attempts between 0 and 3),
  available_at timestamptz not null default now(),
  lease_token uuid,
  started_at timestamptz,
  created_at timestamptz not null default now(),
  error_code text check (length(error_code) <= 100),
  unique (workout_id, workout_version)
);
create table public.nutrition_proposals (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null unique references public.nutrition_jobs(id),
  athlete_id uuid not null references public.profiles(id),
  workout_id uuid not null references public.workouts(id) on delete cascade,
  source_workout_version integer not null,
  source_nutrition_revision integer not null,
  content jsonb not null check (jsonb_typeof(content) = 'object' and octet_length(content::text) <= 20000),
  model_version text not null check (length(model_version) between 1 and 100),
  generation_mode text not null check (generation_mode in ('mock','live')),
  prompt_version text not null default 'general-meals-v1',
  generated_at timestamptz not null default now(),
  status text not null default 'draft' check (status in ('draft','approved','rejected')),
  reviewed_by uuid references public.profiles(id),
  reviewed_at timestamptz,
  review_notes text check (length(review_notes) <= 2000)
);
create index on public.nutrition_jobs(status, available_at);
create index on public.nutrition_proposals(athlete_id, generated_at desc);
alter table public.nutrition_reviewers enable row level security;
alter table public.nutrition_jobs enable row level security;
alter table public.nutrition_proposals enable row level security;
revoke all on public.nutrition_reviewers, public.nutrition_jobs, public.nutrition_proposals from anon, authenticated;
grant select on public.nutrition_reviewers, public.nutrition_jobs, public.nutrition_proposals to authenticated;
grant select, insert, update on public.nutrition_jobs, public.nutrition_proposals to service_role;
grant select on public.workouts, public.nutrition_profiles, public.coach_athletes, public.nutrition_reviewers to service_role;
create policy reviewers_read on public.nutrition_reviewers for select to authenticated
  using (profile_id = auth.uid() or public.academy_role() = 'admin');
create policy jobs_read on public.nutrition_jobs for select to authenticated
  using (public.can_manage_athlete(athlete_id));
create policy proposals_read on public.nutrition_proposals for select to authenticated
  using (public.can_manage_athlete(athlete_id) or
    (athlete_id = auth.uid() and public.academy_role() = 'athlete' and status = 'approved'
      and exists(select 1 from public.workouts w where w.id = workout_id
        and w.version = source_workout_version and w.publication_status = 'published')
      and exists(select 1 from public.nutrition_profiles n where n.athlete_id = nutrition_proposals.athlete_id
        and n.revision = source_nutrition_revision and n.ai_consent_at is not null)));

create function public.version_nutrition_profile() returns trigger
language plpgsql set search_path = '' as $$
begin
  if row(new.birth_date,new.allergies,new.preferences,new.dietary_restrictions,new.ai_consent_at)
      is distinct from row(old.birth_date,old.allergies,old.preferences,old.dietary_restrictions,old.ai_consent_at) then
    new.revision := old.revision + 1;
  end if;
  return new;
end $$;
create trigger version_nutrition_profile before update on public.nutrition_profiles
  for each row execute function public.version_nutrition_profile();

create function public.version_workout() returns trigger
language plpgsql set search_path = '' as $$
begin
  if tg_op = 'UPDATE' then
    if row(new.day,new.title,new.instructions,new.kind,new.start_time,new.throwing_plan,
      new.duration_minutes,new.intensity,new.publication_status)
      is distinct from row(old.day,old.title,old.instructions,old.kind,old.start_time,old.throwing_plan,
      old.duration_minutes,old.intensity,old.publication_status) then
      new.version := old.version + 1;
    else
      new.version := old.version;
    end if;
  else new.version := 1;
  end if;
  return new;
end $$;
create trigger version_workout before insert or update on public.workouts
  for each row execute function public.version_workout();
create function public.queue_nutrition() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.publication_status <> 'published' or new.kind = 'therapy' then return new; end if;
  if tg_op = 'UPDATE' and new.version = old.version then return new; end if;
  -- Queue only consenting adults with a complete schedule. No historic backfill.
  insert into public.nutrition_jobs(workout_id,athlete_id,workout_version,nutrition_revision)
    select new.id,new.athlete_id,new.version,n.revision from public.nutrition_profiles n
    where n.athlete_id = new.athlete_id and n.ai_consent_at is not null
      and n.birth_date <= (current_date - interval '18 years')::date
      and new.duration_minutes is not null and new.intensity is not null and new.start_time is not null
    on conflict do nothing;
  return new;
end $$;
create trigger queue_nutrition after insert or update on public.workouts
  for each row execute function public.queue_nutrition();

-- Called ONLY by Edge Function after getUser authenticates caller. Serialize global cost cap.
create function public.claim_nutrition_job(target uuid, caller uuid)
returns setof public.nutrition_jobs language plpgsql security definer set search_path = '' as $$
declare j public.nutrition_jobs; r text;
begin
  perform pg_advisory_xact_lock(610110006);
  select role into r from public.profiles where id = caller and not must_change_password;
  select * into j from public.nutrition_jobs where id = target for update;
  if j.id is null or r is null or not (r = 'admin' or (r = 'coach' and exists(
    select 1 from public.coach_athletes where coach_id = caller and athlete_id = j.athlete_id))) then
    raise exception 'Not authorized' using errcode = '42501';
  end if;
  if j.status in ('succeeded','skipped') or j.attempts >= 3 or j.available_at > now()
    or (j.status = 'running' and j.started_at > now() - interval '5 minutes') then return; end if;
  if (select count(*) from public.nutrition_jobs where started_at >= current_date) >= 50
    or (select count(*) from public.nutrition_jobs where athlete_id = j.athlete_id
      and started_at >= now() - interval '1 hour') >= 3 then return; end if;
  if not exists(select 1 from public.workouts w join public.nutrition_profiles n on n.athlete_id = w.athlete_id
    where w.id = j.workout_id and w.version = j.workout_version and w.publication_status = 'published'
      and n.revision = j.nutrition_revision and n.ai_consent_at is not null
      and n.birth_date <= (current_date - interval '18 years')::date) then
    update public.nutrition_jobs set status = 'skipped', error_code = 'stale_or_ineligible' where id = target;
    return;
  end if;
  return query update public.nutrition_jobs set status = 'running', attempts = attempts + 1,
    started_at = now(), lease_token = gen_random_uuid(), error_code = null where id = target returning *;
end $$;

create function public.finish_nutrition_job(target uuid, lease uuid, payload jsonb, model text, mode text, failure text default null)
returns void language plpgsql security definer set search_path = '' as $$
declare j public.nutrition_jobs;
begin
  select * into j from public.nutrition_jobs where id = target and lease_token = lease and status = 'running' for update;
  if j.id is null then raise exception 'Expired job lease'; end if;
  if failure is not null then
    update public.nutrition_jobs set status = 'failed', error_code = failure,
      available_at = now() + interval '2 minutes' * attempts, lease_token = null where id = target;
    return;
  end if;
  if not exists(select 1 from public.workouts w join public.nutrition_profiles n on n.athlete_id = w.athlete_id
    where w.id = j.workout_id and w.version = j.workout_version and w.publication_status = 'published'
      and n.revision = j.nutrition_revision and n.ai_consent_at is not null) then
    update public.nutrition_jobs set status = 'skipped', error_code = 'stale', lease_token = null where id = target;
    return;
  end if;
  insert into public.nutrition_proposals(job_id,athlete_id,workout_id,source_workout_version,
    source_nutrition_revision,content,model_version,generation_mode)
    values(j.id,j.athlete_id,j.workout_id,j.workout_version,j.nutrition_revision,payload,model,mode);
  update public.nutrition_jobs set status = 'succeeded', lease_token = null where id = target;
end $$;

create function public.review_nutrition_proposal(target uuid, approved boolean, notes text)
returns void language plpgsql security definer set search_path = '' as $$
declare p public.nutrition_proposals;
begin
  select * into p from public.nutrition_proposals where id = target for update;
  if p.id is null or not coalesce(public.can_manage_athlete(p.athlete_id),false)
    or not exists(select 1 from public.nutrition_reviewers where profile_id = auth.uid()) then
    raise exception 'Qualified assigned reviewer required' using errcode = '42501';
  end if;
  if p.status <> 'draft' or notes is null or length(trim(notes)) not between 1 and 2000 then raise exception 'Invalid review'; end if;
  if approved and (p.generation_mode = 'mock' or not exists(
    select 1 from public.workouts w join public.nutrition_profiles n on n.athlete_id = w.athlete_id
    where w.id = p.workout_id and w.version = p.source_workout_version and w.publication_status = 'published'
      and n.revision = p.source_nutrition_revision and n.ai_consent_at is not null
      and n.birth_date <= (current_date - interval '18 years')::date)) then raise exception 'Mock, stale or ineligible'; end if;
  update public.nutrition_proposals set status = case when approved then 'approved' else 'rejected' end,
    reviewed_by = auth.uid(), reviewed_at = now(), review_notes = trim(notes) where id = target;
end $$;

revoke all on function public.archive_workout_version(), public.version_nutrition_profile(), public.version_workout(), public.queue_nutrition(),
  public.claim_nutrition_job(uuid,uuid), public.finish_nutrition_job(uuid,uuid,jsonb,text,text,text),
  public.review_nutrition_proposal(uuid,boolean,text) from public, anon, authenticated;
grant execute on function public.claim_nutrition_job(uuid,uuid),
  public.finish_nutrition_job(uuid,uuid,jsonb,text,text,text) to service_role;
grant execute on function public.review_nutrition_proposal(uuid,boolean,text) to authenticated;
commit;
