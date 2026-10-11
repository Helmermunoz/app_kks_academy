-- Daily whole-schedule context and a durable, conservative attempt budget.
begin;
alter table public.nutrition_jobs add column source_day date, add column day_signature text;
alter table public.nutrition_proposals add column source_day date, add column day_signature text;
create table public.nutrition_attempts (
  id uuid primary key default gen_random_uuid(),
  job_id uuid references public.nutrition_jobs(id) on delete set null,
  athlete_id uuid not null references public.profiles(id),
  lease_token uuid not null unique,
  reserved_at timestamptz not null default now(),
  budget_day date not null default (now() at time zone 'America/Hermosillo')::date
);
create index on public.nutrition_attempts(athlete_id,budget_day);
alter table public.nutrition_attempts enable row level security;
revoke all on public.nutrition_attempts from public,anon,authenticated,service_role;
grant select on public.nutrition_attempts to service_role;

-- Only the server can read this context. IDs/versions are used for freshness,
-- and stripped from the external provider payload in the Edge Function.
create function public.nutrition_day_context(athlete uuid, target_day date) returns jsonb
language sql stable security definer set search_path='' as $$
  select jsonb_build_object('day',target_day,'position',p.position,
    'activities',coalesce((select jsonb_agg(jsonb_build_object(
      'id',w.id,'version',w.version,'type',w.kind,'title',w.title,
      'instructions',w.instructions,'local_time',w.start_time,
      'duration_minutes',w.duration_minutes,'intensity',w.intensity,
      'throwing_plan',w.throwing_plan) order by w.start_time nulls last,w.id)
      from public.workouts w where w.athlete_id=athlete and w.day=target_day
      and w.publication_status='published'),'[]'::jsonb))
  from public.profiles p where p.id=athlete and p.role='athlete'
$$;
create function public.nutrition_day_signature(athlete uuid, target_day date) returns text
language sql stable security definer set search_path='' as $$
  select md5(public.nutrition_day_context(athlete,target_day)::text)
$$;
revoke all on function public.nutrition_day_context(uuid,date),public.nutrition_day_signature(uuid,date)
  from public,anon,authenticated;
grant execute on function public.nutrition_day_context(uuid,date) to service_role;

create or replace function public.queue_nutrition() returns trigger
language plpgsql security definer set search_path='' as $$
begin
  if new.publication_status<>'published' then return new; end if;
  if tg_op='UPDATE' and new.version=old.version then return new; end if;
  -- All published activity kinds are represented, including gym and therapy.
  -- Missing timing/load is passed as unknown rather than silently dropping a session.
  insert into public.nutrition_jobs(workout_id,athlete_id,workout_version,nutrition_revision,source_day,day_signature)
  select new.id,new.athlete_id,new.version,n.revision,new.day,
    public.nutrition_day_signature(new.athlete_id,new.day)
  from public.nutrition_profiles n where n.athlete_id=new.athlete_id
    and n.ai_consent_at is not null and n.birth_date<=(current_date-interval '18 years')::date
  on conflict do nothing;
  return new;
end $$;

-- Keep the established role/lease/version checks, but expose only the new wrapper.
alter function public.claim_nutrition_job(uuid,uuid) rename to claim_nutrition_job_v1;
revoke all on function public.claim_nutrition_job_v1(uuid,uuid) from public,anon,authenticated,service_role;
create function public.claim_nutrition_job(target uuid, caller uuid)
returns setof public.nutrition_jobs language plpgsql security definer set search_path='' as $$
declare j public.nutrition_jobs; claimed public.nutrition_jobs; local_day date;
begin
  perform pg_advisory_xact_lock(610110006);
  select * into j from public.nutrition_jobs where id=target for update;
  if not exists(select 1 from public.profiles p where p.id=caller and not p.must_change_password
    and (p.role='admin' or (p.role='coach' and exists(select 1 from public.coach_athletes c
      where c.coach_id=caller and c.athlete_id=j.athlete_id)))) then
    raise exception 'Not authorized' using errcode='42501';
  end if;
  local_day := (now() at time zone 'America/Hermosillo')::date;
  if (select count(*) from public.nutrition_attempts where athlete_id=j.athlete_id and budget_day=local_day)>=3
    or (select count(*) from public.nutrition_attempts where budget_day=local_day)>=50 then return; end if;
  if j.day_signature is null or j.day_signature is distinct from
      public.nutrition_day_signature(j.athlete_id,j.source_day) then
    update public.nutrition_jobs set status='skipped',error_code='stale_daily_schedule' where id=target;
    return;
  end if;
  select * into claimed from public.claim_nutrition_job_v1(target,caller);
  if claimed.id is null then return; end if;
  -- Reserve before any network request; failures, expired leases and retries count.
  -- The ledger never resets on edits or deletes. Mock processing also consumes a slot.
  insert into public.nutrition_attempts(job_id,athlete_id,lease_token,budget_day)
    values(claimed.id,claimed.athlete_id,claimed.lease_token,local_day);
  return next claimed;
end $$;
revoke all on function public.claim_nutrition_job(uuid,uuid) from public,anon,authenticated;
grant execute on function public.claim_nutrition_job(uuid,uuid) to service_role;

alter function public.finish_nutrition_job(uuid,uuid,jsonb,text,text,text) rename to finish_nutrition_job_v1;
revoke all on function public.finish_nutrition_job_v1(uuid,uuid,jsonb,text,text,text)
  from public,anon,authenticated,service_role;
create function public.finish_nutrition_job(target uuid, lease uuid, payload jsonb, model text, mode text, failure text default null)
returns void language plpgsql security definer set search_path='' as $$
declare j public.nutrition_jobs;
begin
  select * into j from public.nutrition_jobs where id=target and lease_token=lease and status='running' for update;
  if j.id is null then raise exception 'Expired job lease'; end if;
  if failure is null and (j.day_signature is null or j.day_signature is distinct from
    public.nutrition_day_signature(j.athlete_id,j.source_day)) then
    update public.nutrition_jobs set status='skipped',error_code='stale_daily_schedule',lease_token=null where id=target;
    return;
  end if;
  perform public.finish_nutrition_job_v1(target,lease,payload,model,mode,failure);
  update public.nutrition_proposals set source_day=j.source_day,day_signature=j.day_signature,
    prompt_version='general-daily-meals-v2' where job_id=target;
end $$;
revoke all on function public.finish_nutrition_job(uuid,uuid,jsonb,text,text,text) from public,anon,authenticated;
grant execute on function public.finish_nutrition_job(uuid,uuid,jsonb,text,text,text) to service_role;

create function public.nutrition_proposal_current(athlete uuid, target_day date, signature text) returns boolean
language sql stable security definer set search_path='' as $$
  select (athlete=auth.uid() or public.can_manage_athlete(athlete))
    and signature is not null and signature=public.nutrition_day_signature(athlete,target_day)
$$;
revoke all on function public.nutrition_proposal_current(uuid,date,text) from public,anon;
grant execute on function public.nutrition_proposal_current(uuid,date,text) to authenticated;
alter policy proposals_read on public.nutrition_proposals using (
  public.can_manage_athlete(athlete_id) or (athlete_id=auth.uid() and public.academy_role()='athlete'
    and status='approved' and public.nutrition_proposal_current(athlete_id,source_day,day_signature)
    and exists(select 1 from public.workouts w where w.id=workout_id
      and w.version=source_workout_version and w.publication_status='published')
    and exists(select 1 from public.nutrition_profiles n where n.athlete_id=nutrition_proposals.athlete_id
      and n.revision=source_nutrition_revision and n.ai_consent_at is not null)));
alter function public.review_nutrition_proposal(uuid,boolean,text) rename to review_nutrition_proposal_v1;
revoke all on function public.review_nutrition_proposal_v1(uuid,boolean,text) from public,anon,authenticated,service_role;
create function public.review_nutrition_proposal(target uuid, approved boolean, notes text)
returns void language plpgsql security definer set search_path='' as $$
declare p public.nutrition_proposals;
begin
  select * into p from public.nutrition_proposals where id=target for update;
  if approved and not coalesce(public.nutrition_proposal_current(p.athlete_id,p.source_day,p.day_signature),false)
    then raise exception 'Mock, stale or ineligible'; end if;
  perform public.review_nutrition_proposal_v1(target,approved,notes);
end $$;
revoke all on function public.review_nutrition_proposal(uuid,boolean,text) from public,anon;
grant execute on function public.review_nutrition_proposal(uuid,boolean,text) to authenticated;
commit;
