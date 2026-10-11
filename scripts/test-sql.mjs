// Local SQL only. Emulates Supabase schemas/roles; does not verify live Auth/Storage.
import {readFile,readdir} from 'node:fs/promises';
import {PGlite} from '../.tools/node_modules/@electric-sql/pglite/dist/index.js';
const db = new PGlite();
await db.exec(`
 create role anon; create role authenticated; create role service_role bypassrls;
 create schema auth; create schema storage;
 create table auth.users(id uuid primary key,email text,encrypted_password text);
 create function auth.uid() returns uuid language sql stable as $$
   select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid
 $$;
 grant usage on schema auth,storage to authenticated,service_role;
 grant execute on function auth.uid() to authenticated,service_role;
 create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
 create table storage.objects(id uuid primary key default gen_random_uuid(),bucket_id text,name text,owner uuid);
 alter table storage.objects enable row level security;
 grant select,insert,delete on storage.objects to authenticated;
`);
for (const file of (await readdir('supabase/migrations')).filter(f=>f.endsWith('.sql')).sort()) {
  await db.exec(await readFile(`supabase/migrations/${file}`,'utf8'));
  console.log(`Migration OK: ${file}`);
}
for (const file of ['access.sql','session_videos.sql','nutrition.sql','development.sql','nutrition_proposals.sql','pilot_roles.sql']) {
  await db.exec(await readFile(`supabase/tests/${file}`,'utf8'));
  console.log(`SQL tests OK: ${file}`);
}
await db.close();
