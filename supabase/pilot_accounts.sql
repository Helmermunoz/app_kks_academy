-- Run only after the owner creates these Auth accounts with individual passwords.
-- Creates missing profiles; never changes the role of an existing profile.
begin;
with roster(name,username,role,position) as (values
 ('Andrés Muñoz','andres.munoz','athlete','pitcher'),
 ('Enrique Gastelum','enrique.gastelum','athlete','pitcher'),
 ('Brayan Orrantia','brayan.orrantia','athlete','pitcher'),
 ('Alejandro Urías','alejandro.urias','athlete','catcher'),
 ('Abraham Vidaña','abraham.vidana','coach',null),
 ('Miguel Muñoz','miguel.munoz','viewer',null),
 ('Wendy Almodóvar','wendy.almodovar','nutrition',null)
)
insert into public.profiles(id,name,username,role,position,must_change_password)
select u.id,r.name,r.username,r.role,r.position,false
from roster r join auth.users u on u.email=r.username||'@users.kksacademy.invalid'
on conflict(id) do nothing;
update public.profiles set position='pitcher'
where username in ('andres.munoz','enrique.gastelum','brayan.orrantia') and role='athlete';
update public.profiles set position='catcher'
where username='alejandro.urias' and role='athlete';
commit;
