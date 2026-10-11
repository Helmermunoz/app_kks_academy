# Entrega de preparación — 2026-10-11

Rama: `codex/railway-pwa-nutrition`. Base auditada: `bf76bb753708175ba089c5f97434a5b21bd8edc6`.

## Existente conservado

Auth por contraseña, roles/coach asignado, calendario diario/semanal/mensual, sesiones, completados, videos/galería, reportes de progreso, reseñas e InBody implementados en código. Pantalla pública de login cargada en Pages. Persistencia/roles con Supabase real no verificados: no se recibieron cuentas de prueba ni sesión de dashboard.

## Añadido/corregido

- Docker multietapa Flutter 3.47.5 + NGINX, PORT, SPA fallback, /healthz, revalidación y rechazo de claves servidor en build.
- Nombre/iconos/colores PWA, worker de red sin caché privada, bootstrap propio. Sin modo offline de datos privados.
- Publicación/duración/intensidad opcionales, versionado y archivo de sesiones; componentes existentes reutilizados.
- Propuestas de alimentación privadas, revisión por profesional acreditado y asignado, borradores de prueba no publicables.
- Cola durable/idempotente, intento en segundo plano tras publicación material, reintento manual si falla, autorización JWT/SQL, leases, backoff, límites de intentos y consumo, esquema validado, generación mock por defecto.
- Consentimiento solo administrado por servidor, adultos únicamente, sin transferencia de InBody o identificación a OpenAI.
- El cambio de identidad/cierre de sesión elimina páginas privadas abiertas.
- Workflow de validación separado, sin modificar pages.yml.

## Validaciones

| Comprobación | Resultado |
| --- | --- |
| Flutter 3.47.5 / Dart 3.13.4 | SDK instalado verificado |
| flutter pub get | Pasó; lockfile conservado |
| Análisis baseline | Sin incidencias |
| Tests baseline | 29 pasaron |
| Análisis después de mejoras | Sin incidencias |
| Tests después de propuestas | 32 pasaron; incluye mock, revisión y sesión estructurada |
| Tests finales con limpieza de rutas privadas | 33 pasaron |
| Build web normal y flag de asistente true | Ambos pasaron |
| Deno check Edge Function | Pasó, Deno 2.9.6 |
| Deno schema tests | 2 pasaron, cero llamadas OpenAI |
| SQL local PGlite 0.5.8 | Seis migraciones y cinco suites pasaron (access, session_videos, nutrition, development, nutrition_proposals) |
| JavaScript worker/registro | node --check pasó |
| Manifiesto HTTP local | 200, nombre KKs Academy, standalone |
| Vista local | Pantalla de preparación verificada en escritorio y ancho 390; build sin configuración pública a propósito |
| Docker/NGINX | Preparado, no ejecutado: Docker no disponible |
| Instalación iPhone/Android físicos | No verificada; procedimiento en RELEASE.md |
| Supabase/Auth/Storage en vivo | No verificado; dashboard requiere login |
| OpenAI real | Desactivado, no configurado, sin consumo pagado |
| Railway | Servicio existente fallido con Railpack; no se desplegó esta rama |

PGlite emula esquemas auth/storage y roles de PostgreSQL: valida SQL/RLS, no el servicio real de Auth, Storage o Edge Functions. No confundir los tests con validación productiva.

Para reproducir SQL: `npm install --prefix .tools --save-exact @electric-sql/pglite@0.5.8`, después `node scripts/test-sql.mjs`. Instalar Deno oficial 2.9.6 para ejecutar check/test. No hacen falta claves o conexión a Supabase.

## Archivos

Cambios Flutter: academy_portal.dart, academy_repository.dart, nutrition_page.dart, nutrition_proposals.dart, session_details.dart. Web: index.html, manifest.json, favicon/iconos, pwa.js, academy-sw.js, flutter_bootstrap.js. Backend: migración 006, función nutrition-assistant y validación de esquema, config.toml, pruebas SQL. Deploy/calidad: Dockerfile, .dockerignore, deploy/default.conf.template, railway.toml, quality.yml, scripts de SQL/iconos, tests Flutter. Documentación: README y docs/AUDIT.md, RELEASE.md, DELIVERY.md.

## Próximos pasos y límites

1. Revisar este PR y elegir Docker/NGINX frente al Docker/Caddy del PR #1 de Railway. No se fusionó, cerró o cambió el PR existente.
2. Iniciar sesión en Supabase para comprobar migraciones existentes; crear/autorizar cuentas y proyecto staging. Revisar/aprobar y probar 006 ahí antes de producción.
3. Registrar acreditación y consentimiento, desplegar función en mock y verificar flujo extremo a extremo en staging.
4. Aprobar despliegue/coste de Railway, reutilizar servicio existente, configurar solo valores públicos, verificar healthcheck/SPA/login y dispositivos. Conservar Pages hasta completar la verificación.
5. OpenAI real queda sujeto a aprobación de gasto, consentimiento y prueba con modelo especificado por propietario. Hostinger DNS es una etapa posterior.

No se implementaron diagnósticos clínicos, planes para menores, cron automático, moderación de videos o conversaciones persistentes. La galería comunitaria conserva su audiencia actual; revisar consentimiento antes de videos reales de menores. Estas limitaciones están explícitas en auditoría y guía.
