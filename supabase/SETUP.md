# Activar las cuentas de KKs Academy

Esta etapa implementa cuentas, permisos, sesiones con lugar y horario, avisos de
terapia y videos compartidos para una sola academia por proyecto de Supabase.
El análisis de postura todavía está pendiente.

## 1. Crear el proyecto

Crear un proyecto en Supabase. Guardar la contraseña de la base de datos fuera del
repositorio. En SQL Editor, ejecutar una sola vez
`migrations/202609230001_academy.sql` completo. Después ejecutar
`migrations/202609230002_profile_service_permissions.sql` para dar a la función
del servidor permiso de lectura y creación de perfiles. Este segundo archivo
también se debe aplicar a los proyectos que ya ejecutaron la primera migración;
no es necesario repetir la primera.

Después ejecutar `migrations/202609230003_session_details_videos.sql` una sola vez.
Agrega los campos de sesiones, la tabla de videos y el bucket privado
`session-videos` con sus políticas. No repetir migraciones ya aplicadas.

Las sesiones anteriores conservan sus datos y se clasifican como Entrenamiento;
editar cada una para indicar Bullpen, Pista o Terapia y completar lugar y hora.
El plan de tiros es texto definido por el entrenador (cantidad, distancia,
intensidad, lanzamientos y descansos); la app no prescribe cargas automáticamente.
El aviso de terapia se muestra dentro de la app para citas pendientes desde hoy,
usando la fecha local del dispositivo. No envía notificaciones push ni correos.

Desde cada sesión deportiva se pueden subir videos de hasta 50 MB (MP4, WebM,
MOV); MP4 ofrece mayor compatibilidad entre navegadores. Todos los miembros con
contraseña personal pueden verlos, incluyendo fecha, tipo y nombre del atleta.
Las instrucciones, ubicación y planes privados no se comparten en la galería.
Las terapias no admiten videos compartidos. Las URLs de reproducción vencen en
una hora: volver a abrir el video genera otra. Cada listado muestra los últimos
100 videos. La eliminación y moderación se gestiona desde Supabase por ahora;
si una carga se interrumpe puede quedar un archivo sin ficha, que debe revisarse
en Storage. No hay carga reanudable, comentarios ni análisis del esqueleto todavía.

Si la galería informa `PGRST205`, ejecutar la consulta de solo lectura
`tests/video_setup_diagnostic.sql` en SQL Editor. Si los tres valores son falsos,
falta aplicar `003`: ejecutarla completa una sola vez. Si todo existe pero la API
no encuentra la tabla, ejecutar `notify pgrst, 'reload schema';` y volver a intentar.
Si el resultado es parcial, revisar el esquema antes de repetir la migración.
No conceder acceso a `anon` para resolver este error: los videos requieren una cuenta.

En Authentication, desactivar el registro público de usuarios. Las cuentas de
atletas y entrenadores se crearán desde el panel del administrador de esta app.
No se usan metadatos editables del usuario para decidir permisos.

### Alimentación e InBody

Ejecutar una vez `migrations/202609230004_nutrition_inbody.sql` para habilitar
el perfil de alimentación y el historial InBody. Los atletas pueden registrar
sus propios datos; administración y entrenadores asignados pueden consultarlos
y registrarlos. Otros atletas y entrenadores sin asignación no tienen acceso.
No existe todavía un rol independiente de nutriólogo.

Las mediciones se agregan al historial, no se reemplazan. Si hay un error de captura,
administración debe corregirlo desde Supabase; no hay edición/borrado en la app.
Los valores de estatura, peso, grasa, músculo y metabolismo basal son transcripciones
del reporte, no diagnósticos ni metas de ingesta. Los campos opcionales vacíos quedan
sin medición. Se muestran las últimas 500 evaluaciones; las anteriores se conservan.
La gráfica permite elegir la medida y usa la fecha de evaluación como eje horizontal.
Las observaciones se ingresan manualmente, sin verificar la identidad profesional
del autor del reporte. No hay OCR ni conexión con InBody ni un proveedor de IA.

Ejecutar `tests/nutrition.sql` solo en un proyecto de prueba para comprobar el
aislamiento entre atletas, acceso del entrenador asignado y conservación del historial.
Después comprobar guardado/recarga desde la app con cuentas distintas.

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

Para editar `supabase/functions/create-account/index.ts` en VS Code, instalar
la extensión oficial `denoland.vscode-deno` y el ejecutable Deno. En los ajustes
del workspace, configurar `"deno.enablePaths": ["./supabase/functions"]`.
Si Deno no está en PATH, indicar su ruta en `deno.path`. El archivo usa Deno y
una importación HTTPS: el analizador TypeScript estándar no reconoce ese entorno.
Comprobar los tipos con `deno check supabase/functions/create-account/index.ts`;
este comando no ejecuta la función ni crea cuentas. Después de configurar el
editor, ejecutar `Developer: Reload Window` desde la paleta de comandos.

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

## Seguimiento, bullpen y revisión de videos (actualización 005)

Después de aplicar 001–004, ejecutar **una vez y completo**
`migrations/202609240005_development.sql` en SQL Editor. Debe terminar con
`Success. No rows returned`. No sustituye ni requiere volver a ejecutar las anteriores.
Actualizar la web después del despliegue en GitHub Pages.

El administrador/entrenador verá **Panel del entrenador** y el atleta
**Mi seguimiento y resultados**. El período inicial abarca los últimos 30 días
y los próximos 7; se puede cambiar el rango y filtrar por atleta, sesiones sin
completar, molestias o videos pendientes de revisión.

- Los resultados son privados: atleta propietario, entrenador asignado y administrador.
- Atleta y equipo pueden registrar/editar resultados, con atribución y fecha del servidor.
- La revisión de video es privada y solo el equipo puede escribirla. El atleta la consulta.
  La comunidad conserva acceso al video, sin acceso al reporte ni a la revisión.
- Guardar resultados no marca automáticamente la sesión como completada.
- Los conteos y velocidad se introducen manualmente; velocidad en mph, solo con radar.
  Las cantidades por tipo se escriben en texto. No hay captura automática ni mapa de lanzamientos.
- Las molestias aparecen como aviso en el panel al actualizar. No hay notificaciones push ni diagnóstico.
- Se guarda una revisión actual por video, con estado, observación y segundo de referencia.
  No incluye comparación simultánea, dibujo, análisis de esqueleto ni historial de ediciones.

Validación manual: guardar un bullpen, recargar y confirmar persistencia; añadir una
revisión como entrenador y consultarla como atleta; comprobar que otro atleta solo
ve el video comunitario. Quitar la asignación del entrenador y verificar que deja
de leer los reportes. `tests/development.sql` contiene pruebas RLS para un proyecto
de prueba; no sustituye probar Auth y reproducción con cuentas reales.

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

Ejecutar también `tests/session_videos.sql` en un proyecto vacío de prueba con
las tres migraciones aplicadas. Comprueba permisos de sesiones y videos con
metadatos simulados. Después probar la carga y reproducción de un archivo real,
su persistencia al recargar, visualización con otro atleta y rechazo de una carga
en una sesión ajena. Estas pruebas de servidor requieren ejecutarse en Supabase.

Los entrenamientos se cargan al entrar, al cambiar de atleta y al pulsar Actualizar;
no hay sincronización en tiempo real. Editar el contenido conserva la marca de
completado del atleta. La recuperación de acceso se gestiona por el administrador
desde Supabase en esta primera etapa. Para entregar una nueva contraseña temporal,
actualizarla desde Auth y después restablecer `must_change_password = true` desde
SQL Editor para ese perfil, antes de entregar el acceso.

Referencias: [Flutter](https://supabase.com/docs/guides/getting-started/quickstarts/flutter),
[RLS](https://supabase.com/docs/guides/database/postgres/row-level-security).
