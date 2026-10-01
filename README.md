# KKs Academy

App web en Flutter para seguimiento de jugadores de béisbol de todas las posiciones.

## Cuentas y entrenamientos personales

La app incluye acceso con Supabase, administrador, entrenadores asignados a atletas,
creación de cuentas con contraseña temporal, entrenamientos privados y registro de
sesiones completadas. Para activar estas funciones, seguir [la guía de configuración](supabase/SETUP.md).
La migración y la función del servidor están incluidas, pero requieren un proyecto
de Supabase configurado y desplegado. Sin configuración se puede explorar la demo.

Las sesiones incluyen tipo, lugar, horario y plan de tiros. Las citas de terapia
pendientes muestran un aviso dentro de la app. Se pueden subir videos por sesión
y consultar la galería de la academia con una cuenta activa. Requiere aplicar la
migración `202609230003_session_details_videos.sql` en Supabase.
Las métricas de movimiento todavía están pendientes.

El apartado Mi alimentación / InBody permite registrar fecha de nacimiento,
objetivos, alergias, preferencias y presupuesto, además de evaluaciones InBody
con historial y gráfica por medida. Requiere la migración
`202609230004_nutrition_inbody.sql`. Los datos son privados por atleta y permisos
de entrenador; no se envían a IA. La generación de menús sigue pendiente.

## Ejecutar

```sh
flutter pub get
flutter run -d chrome
```

## Demostración de diseño

- Calendario semanal y programa según posición.
- Vista de entrenador de demostración para asignar plantillas.
- Registro temporal de entrenamientos completados.
- Videos locales por día, categoría y autor, reproducción lenta y comentarios con tiempo.
- Diseño con Andrés Muñoz y los pitchers indicados por el propietario.

**Es una demostración:** no hay autenticación, permisos reales ni base de datos. Videos, comentarios y cambios se pierden al recargar. Los archivos de video no se suben a un servidor. El cambio de perfil no ofrece seguridad.

## Seguimiento del atleta

El panel del entrenador reúne sesiones, cumplimiento, reportes de molestias y videos
pendientes de revisión; el atleta dispone de su propio seguimiento. Permite filtrar
por fechas y atleta, registrar resultados de bullpen (conteos, strikes y velocidad
manual en mph), esfuerzo y observaciones, y consultar correcciones privadas del
entrenador con un segundo de referencia del video.

Requiere aplicar `supabase/migrations/202609240005_development.sql` una vez después
de 001–004. Instrucciones y límites en `supabase/SETUP.md`.

## Próximas etapas

1. Crear el proyecto de Supabase y aplicar la configuración incluida.
2. Verificar permisos con las pruebas SQL y cuentas reales de prueba.
3. Incorporar posiciones principales/secundarias por atleta.
4. Ampliar el plan de tiros de texto con ejercicios y cantidades estructuradas.
5. Conservar versiones e historial al modificar posiciones o programas; el prototipo todavía no lo implementa.
6. Incorporar planes de alimentación y asignación de profesionales a las citas de terapia.
7. Ampliar la revisión privada de videos con conversaciones, moderación y análisis de movimiento.
8. Probar aislamiento de datos entre alumnos y permisos del entrenador antes de usar datos reales.

No incluir credenciales ni videos de alumnos en Git. Configurar secretos en el entorno del servidor.

## Comprobaciones

```sh
flutter analyze
flutter test
flutter build web
```

## Deployment (GitHub Pages)

Production URL: https://helmermunoz.github.io/app_kks_academy/

The existing `.github/workflows/pages.yml` workflow, **Publish Flutter web**,
starts automatically on pushes to `main`, or manually from Actions using
**Run workflow** with branch `main`. It installs Flutter 3.47.5, runs dependency
resolution, analysis and tests, then builds and uploads `build/web` and deploys
that artifact to GitHub Pages. `build/` is intentionally ignored by Git;
a local `flutter build web` does not publish the website.

The release build uses `--base-href /app_kks_academy/` and the existing repository
variables `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` as Dart defines.
Do not change these variables to troubleshoot a stale browser view.
A local build without those defines shows the setup/demo entry rather than
validating the configured production login.

For an existing site, verify settings before changing them. The workflow expects
**Settings > Pages > Build and deployment > Source: GitHub Actions**.
No settings change is needed when the workflow's deployment job already succeeds.
After pushing, open **Actions > Publish Flutter web**, select the run for the
pushed commit, and confirm both `build` and `deploy` succeed. Open the deployment
URL from the `github-pages` environment.

If the screen appears old, open the production URL in a private/incognito window,
then sign in as an athlete to verify **Mi entrenamiento**, the date selector and
**Hoy**. **Explorar demostración** opens a separate example screen whose weekly
layout is unchanged. Try a hard reload (`Ctrl+Shift+R`) in the regular browser.
The currently deployed Flutter service worker unregisters itself; it does not
cache the app. An older browser registration can still require an update:
in Chrome/Edge, open **Developer Tools > Application > Service workers**, locate
the registration for this site's scope and click **Update**, then reload.
If it persists, unregister only that site's worker and reload. Avoid clearing all
site storage, which would also remove the local sign-in session.
GitHub Pages currently serves these assets with a ten-minute cache lifetime;
a fresh deployment may take time to appear through browser/CDN caches.
