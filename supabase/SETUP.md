# Activar las cuentas de KKs Academy

Esta etapa implementa cuentas, permisos y entrenamientos personales para una sola
academia por proyecto de Supabase. Los videos compartidos y el análisis de postura
son la siguiente etapa; los videos existentes siguen siendo una demostración local.

## 1. Crear el proyecto

Crear un proyecto en Supabase. Guardar la contraseña de la base de datos fuera del
repositorio. En SQL Editor, ejecutar una sola vez
`migrations/202609230001_academy.sql` completo. Después ejecutar
`migrations/202609230002_profile_service_permissions.sql` para dar a la función
del servidor permiso de lectura y creación de perfiles. Este segundo archivo
también se debe aplicar a los proyectos que ya ejecutaron la primera migración;
no es necesario repetir la primera.

En Authentication, desactivar el registro público de usuarios. Las cuentas de
atletas y entrenadores se crearán desde el panel del administrador de esta app.
No se usan metadatos editables del usuario para decidir permisos.

## 2. Primer administrador

En Authentication > Users, crear la cuenta del propietario con un correo real y
una contraseña temporal de al menos 12 caracteres, con el correo confirmado.
Copiar su UUID y ejecutar en SQL Editor, reemplazando los valores:

```sql
insert into public.profiles (id, name, role)
values ('UUID-DEL-USUARIO', 'Nombre del administrador', 'admin');
```

La app pedirá cambiar la contraseña al entrar. El servidor habilita el acceso a
los planes cuando Auth confirma el cambio. No cambiar manualmente el indicador
`must_change_password` para las cuentas reales.

## 3. Publicar la función de creación de cuentas

Desde este directorio de proyecto, con Supabase CLI instalado:

```sh
supabase login
supabase link --project-ref TU_PROJECT_REF
supabase functions deploy create-account
```

La configuración `verify_jwt = false` permite que el manejador valide el token
directamente con `auth.getUser`; el manejador siempre exige un administrador
autenticado y con la contraseña temporal ya cambiada. No permite crear otros
administradores desde la app. Las variables internas `SUPABASE_URL` y
`SUPABASE_SERVICE_ROLE_KEY` son proporcionadas por Supabase a la función.
La clave de servicio **nunca** se coloca en Flutter ni en variables de compilación.

## 4. Conectar Flutter

Copiar Project URL y la clave **publishable** desde el panel Connect del proyecto.
Estos dos valores están destinados al cliente; la privacidad depende de las
políticas RLS incluidas en la migración.

```sh
flutter run -d chrome --dart-define=SUPABASE_URL=https://TU_PROJECT_REF.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_TU_CLAVE
```

Para GitHub Pages, crear las variables del repositorio `SUPABASE_URL` y
`SUPABASE_PUBLISHABLE_KEY`. El workflow ya las pasa a la compilación.
Sin configuración, la app muestra una pantalla de preparación y un enlace a la
demostración. La demostración no guarda datos ni proporciona cuentas privadas.

## 5. Comprobar antes de usar datos reales

Ejecutar `tests/access.sql` en SQL Editor sobre un proyecto de prueba después de
la migración. Los datos de prueba se revierten al terminar. Si falla una aserción,
ejecutar `rollback;` antes de continuar. Esta prueba verifica RLS usando los roles
de Postgres y tokens simulados; no sustituye la prueba del servicio Auth real.

Después, probar con un administrador, dos entrenadores y dos atletas:

1. Cambiar la contraseña temporal del administrador y crear las otras cuentas.
2. Asignar un atleta a cada entrenador.
3. Entrar con cada cuenta y cambiar su contraseña temporal.
4. Crear y editar entrenamientos para el atleta asignado.
5. Verificar que cada atleta solo ve sus planes, incluso al intentar consultar
   directamente la API con su sesión y el UUID del otro atleta.
6. Marcar una sesión como completada, recargar y comprobar que sigue completada.
7. Quitar una asignación y comprobar que el entrenador pierde acceso al recargar.
8. Intentar invocar `create-account` sin sesión y como atleta: debe rechazar ambas.
9. Cerrar sesión y comprobar que ya no se muestran datos privados.

Los entrenamientos se cargan al entrar, al cambiar de atleta y al pulsar Actualizar;
no hay sincronización en tiempo real. Editar el contenido conserva la marca de
completado del atleta. La recuperación de acceso se gestiona por el administrador
desde Supabase en esta primera etapa. Para entregar una nueva contraseña temporal,
actualizarla desde Auth y después restablecer `must_change_password = true` desde
SQL Editor para ese perfil, antes de entregar el acceso.

Referencias: [Flutter](https://supabase.com/docs/guides/getting-started/quickstarts/flutter),
[RLS](https://supabase.com/docs/guides/database/postgres/row-level-security).
