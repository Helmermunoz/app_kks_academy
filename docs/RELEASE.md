# Preparar Railway PWA

## Estado y aprobación

No se ha desplegado Railway, aplicado 006 ni activado OpenAI. GitHub Pages y sus variables se conservan. Las siguientes acciones sobre producción requieren aprobación del propietario. Mantener Pages hasta comprobar Railway con cuentas de prueba.

## Base de datos y nutrición

1. Comprobar `supabase_migrations.schema_migrations` y el esquema; 001–005 deben existir. Hacer backup y aplicar `supabase/migrations/202610110006_nutrition_proposals.sql` **primero en staging**. No repetir migraciones ya aplicadas.
2. Ejecutar pruebas SQL de permisos existentes y nuevas. Comprobar también Auth real con admin, dos coaches y dos atletas. La prueba local de Postgres no demuestra integración Supabase.
3. Verificar acreditación profesional fuera de la app. Registrar al coach/admin revisor, desde SQL Editor autorizado:

```sql
insert into public.nutrition_reviewers(profile_id,qualification_reference)
values ('UUID-PROFESIONAL','Referencia verificada por administración');
```

La acreditación no concede acceso a otros atletas: también requiere asignación o rol admin. No dar a usuarios permiso directo para cambiar aprobaciones o autoacreditarse.

4. Obtener y registrar consentimiento explícito de un adulto para enviar a OpenAI **preferencias, alergias, restricciones y tipo/fecha/hora/duración/intensidad del entrenamiento**. Informar finalidad, proveedor, revisión obligatoria y retirada. La app no envía nombre, UUID, nacimiento, InBody, presupuesto, ubicación ni objetivos clínicos.

```sql
update public.nutrition_profiles
set ai_consent_at = now(), ai_consent_by = 'UUID-ADMIN',
    ai_consent_reference = 'Referencia de consentimiento conservada por academia'
where athlete_id = 'UUID-ADULTO';
-- Retirada: invalida propuestas vigentes y evita nuevas generaciones.
update public.nutrition_profiles
set ai_consent_at = null, ai_consent_by = null, ai_consent_reference = null
where athlete_id = 'UUID-ATLETA';
```

**Menores y nacimiento desconocido quedan bloqueados para IA**, incluso con consentimiento de tutor. No se implementa una vía clínica para menores; deben recibir atención profesional independiente. Nunca usar una fecha falsa para habilitarla.

5. Desplegar la función solo tras aprobación: `supabase functions deploy nutrition-assistant`. Secretos del servidor: `NUTRITION_ENABLED=true`, `NUTRITION_MODE=mock`. Supabase proporciona URL y service role. No poner service role ni OpenAI en Railway frontend, Flutter o GitHub. Configurar secretos mediante panel o archivo local ignorado, no argumentos con claves en el historial.
6. Compilar con `--dart-define=ENABLE_NUTRITION_ASSISTANT=true` después de aplicar 006. Por defecto false: clientes existentes no consultan las tablas nuevas ni escriben los campos nuevos. Probar mock: publicar sesión deportiva con hora, duración e intensidad, como coach asignado. Aparece un trabajo pendiente; abrir Propuestas y procesarlo. El borrador de prueba no puede aprobarse ni mostrarse al atleta.
7. Solo tras consentimiento, aprobación de gasto y validación profesional habilitar `NUTRITION_MODE=live`, `NUTRITION_LIVE_APPROVED=true`, `OPENAI_API_KEY` y `OPENAI_MODEL` (modelo con Structured Outputs validado por el propietario). Ningún modelo pagado se elige o activa automáticamente. Usar proyecto OpenAI separado con presupuesto/alertas y límites del proveedor.

Hay una propuesta por versión de sesión. Cambios materiales generan otra versión; guardar sin cambios o abrir una página no genera trabajos. No se genera en cada carga ni se publica automáticamente. Trabajos persisten; el coach los procesa desde Propuestas. No hay cron instalado. Fallos reintentables se procesan manualmente después del backoff (2, 4, 6 minutos), máximo tres intentos, lease de cinco minutos. Si una llamada tuvo éxito pero el guardado se interrumpió, puede repetirse el gasto en el reintento; se impide guardar propuestas duplicadas. Las generaciones están limitadas a tres trabajos por atleta/hora y cincuenta trabajos/día en SQL. El coste máximo adicional está limitado por tres intentos y 1800 tokens de salida por intento; activar también límites en el proveedor.

El profesional puede aprobar/rechazar con notas; mock, versiones viejas o retirada de consentimiento impiden aprobar. Una actualización de alergias/preferencias o entrenamiento deja de mostrar propuestas anteriores al atleta. El texto generado nunca garantiza seguridad frente a alergias ni prescribe cantidades clínicas.

## Railway

1. Revisar PR y aprobar despliegue/coste. Ya existe `app_kks_academy` en `secure-perfection`, con build fallido de Railpack y sin dominio público. Reutilizar ese servicio y seleccionar la rama aprobada, sin crear recursos duplicados. Railway detecta Dockerfile; railway.toml configura /healthz. El PR #1 de Railway ofrece Docker/Caddy alternativo: elegir una estrategia antes de merge. No conectar despliegue automático de main hasta revisar la estrategia.
2. Variables públicas de compilación: `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY`. Docker exige ambos; builds sin ellas fallan en lugar de desplegar una demo accidental. `ENABLE_NUTRITION_ASSISTANT=false` hasta habilitar la migración. No usar secretos de servidor como build args.
3. Generar dominio Railway HTTPS; comprobar /healthz (200), /, /manifest.json, assets y refresco de una ruta SPA. Archivos inexistentes deben devolver 404.
4. En Supabase Auth agregar las URLs exactas HTTPS de Railway y las rutas de retorno usadas. Conservar URL Pages; no reemplazar Site URL hasta verificar. Login actual usa contraseña; verificar persistencia/refresco/logout y los flujos de recuperación que admin habilite.
5. Probar roles, sesión, completado, videos y propuestas con datos de prueba. GitHub Pages continúa separado con su base-href actual.

Build local opcional con Docker instalado:

```sh
docker build --build-arg SUPABASE_URL=https://PROJECT.supabase.co --build-arg SUPABASE_PUBLISHABLE_KEY=sb_publishable_PUBLIC -t kks-pwa .
docker run --rm -p 8080:8080 -e PORT=8080 kks-pwa
```

No se ejecutó Docker aquí; validar el contenedor antes de producción. Ubuntu/NGINX usan versiones fijas de etiqueta; para mayor reproducibilidad fijar digests tras validar imágenes oficiales.

## Instalación y actualización

El manifiesto usa nombre, colores y monograma KKs. URLs relativas mantienen Pages en subruta y Railway en raíz. Worker propio de red, sin Cache Storage ni contenido offline. Auth mantiene su sesión mediante la librería Supabase; esto es independiente del worker. No existe modo offline para información privada.

Android Chrome: HTTPS, abrir app, menú Instalar app/Añadir a pantalla de inicio; confirmar standalone, icono, rotación y login. iPhone Safari: Compartir > Añadir a pantalla de inicio; abrir desde icono y verificar sesión, videos y teclado. El aviso de instalación depende del navegador; no se promete un botón automático universal. No se han probado dispositivos físicos.

Al cargar se comprueba worker actualizado; no se fuerza recarga en medio de formularios. Volver a abrir/recargar trae assets desde red. NGINX revalida assets con no-cache. Pages conserva sus cabeceras/cache de CDN existentes. Un worker Flutter antiguo puede necesitar actualizarse/desregistrarse solo para el scope de esta app; no borrar todo el almacenamiento ni caches de otros sitios.

## Hostinger después

Tras verificar Railway, agregar dominio personalizado en Settings > Networking y copiar **el registro/valor exacto que Railway muestre** al DNS de Hostinger. No inventar IP ni borrar MX/TXT de correo. Esperar propagación, verificar certificado HTTPS, SPA, manifiesto/scope y retorno Auth. Añadir el dominio exacto a redirect allowlist de Supabase. Conservar Pages/Railway alternativo hasta probar el dominio.

## Rollback

Desactivar primero `NUTRITION_ENABLED`, compilar frontend con flag false y restaurar imagen/rama anterior. Datos antiguos siguen en las tablas existentes; no se requiere borrar propuestas ni versiones. Si se revierte lógica SQL, deshabilitar triggers queue_nutrition, version_workout, archive_workout_version y version_nutrition_profile en una migración revisada. Restaurar workouts_read a su expresión de 001 si se retira la publicación. No eliminar columnas/tablas con datos sin backup y aprobación; el rollback preferido conserva las adiciones inactivas.

Referencias: [Railway Dockerfiles](https://docs.railway.com/builds/dockerfiles), [OpenAI Structured Outputs](https://developers.openai.com/api/docs/guides/structured-outputs?api-mode=responses).
