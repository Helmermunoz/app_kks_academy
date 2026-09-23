-- Explicit server permissions are needed when automatic table grants are disabled.
-- create-account reads the caller's role and inserts new profiles.
-- Browser roles and row-level security remain unchanged.
begin;
grant usage on schema public to service_role;
grant select, insert on table public.profiles to service_role;
commit;
