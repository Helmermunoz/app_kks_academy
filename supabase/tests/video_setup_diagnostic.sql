-- Read-only setup check. Safe to run in the production SQL Editor.
select
  to_regclass('public.session_videos') is not null as tabla_videos_existe,
  exists(select 1 from storage.buckets where id = 'session-videos') as almacenamiento_existe,
  exists(select 1 from information_schema.columns where table_schema = 'public'
    and table_name = 'workouts' and column_name = 'kind') as tipo_sesion_existe;
