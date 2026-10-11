# Auditoría inicial — 2026-10-11

Base: `bf76bb753708175ba089c5f97434a5b21bd8edc6`, rama principal descargada sin cambios.

| Área | Evidencia y estado |
| --- | --- |
| Auth y roles | Repositorio Supabase real, login por contraseña, cierre de sesión, contraseña temporal y función administrativa create-account. Roles en profiles, permisos por asignación y RLS en 001–005. Sin cuentas de prueba autorizadas: persistencia y aislamiento reales pendientes. |
| Calendario | Ya existe selector diario, tira semanal, mes, Hoy, gestos y marcas de fechas; el atleta consulta sesiones reales por fecha. Historial accesible por calendario y panel de seguimiento. |
| Entrenamientos | Personal crea/edita sesiones del atleta seleccionado, con tipo, lugar, hora e instrucciones. RLS limita asignaciones. Sin duración/intensidad estructuradas ni versiones/publicación explícita inicialmente. |
| Videos | Bucket privado, URLs firmadas de una hora, máximo 50 MB, galería compartida intencionalmente con todos los miembros. Revisiones privadas; comentarios temporales pertenecen a la demo. No hay moderación o conversaciones persistentes. |
| Progreso | Reportes de sesiones, esfuerzo, molestias, velocidad manual y revisión actual por video implementados. No hay historial de ediciones de revisiones ni análisis de movimiento. |
| Nutrición/InBody | Tablas existentes nutrition_profiles e inbody_measurements; preferencias/alergias/objetivos/presupuesto y gráficas reales en código. Sin generación de menús o revisión profesional inicialmente. |
| Demo | Ruta separada, estado en memoria, aviso explícito. No prueba la base de datos. |
| Web publicada | GitHub Pages abrió la pantalla de login en navegador el 2026-10-11. Esto verifica carga pública, no Auth ni funcionamiento de Supabase. |
| PWA | Manifiesto standalone pero nombre/descripción/color genéricos e iconos Flutter. Sin estrategia propia de caché/update. Instalación en dispositivos físicos pendiente. |
| Deploy | Workflow Pages con Flutter 3.47.5, analyze/test/build; base-href /app_kks_academy/. Sin Docker/Railway inicialmente. No cambiar Pages ni sus variables. |
| Calidad | Tests de widgets con repositorios simulados, calendario, sesiones, nutrición, desarrollo, errores de video. SQL de RLS para proyecto de pruebas. Resultados actuales en DELIVERY.md. |

## Bloqueos priorizados

1. No hay evidencia autorizada de las migraciones aplicadas, cuentas reales de prueba ni pruebas RLS ejecutadas. Validar antes de datos reales.
2. La galería revela nombre/fecha/video a cualquier miembro por diseño; revisar consentimiento y audiencia, especialmente menores, antes de producción.
3. La IA necesita consentimiento explícito de transferencia, profesional acreditado, presupuesto y configuración del servidor. No activar automáticamente.
4. Railway requiere aprobación para desplegar y generar gastos; Docker y dispositivos iPhone/Android no están disponibles para validación aquí.
5. Videos, reseñas e InBody actuales se conservan. Nuevas migraciones deben revisarse y probarse fuera de producción.

## Railway observado en vivo

El servicio `app_kks_academy` del proyecto `secure-perfection` existe, no tiene dominio expuesto y mostró FAILED: Railpack no pudo preparar el build. El PR #1 generado por Railway ya propone Docker + Caddy. Este PR de preparación propone una alternativa Docker + NGINX con healthcheck, validación de clave pública y estrategia PWA; revisar ambas alternativas y elegir una, sin fusionar dos Dockerfiles incompatibles. No se modificó ni cerró el PR #1.

Supabase redirigió a inicio de sesión: no se verificaron tablas o usuarios reales. Railway está accesible para lectura; no se efectuaron despliegues ni cambios de variables.

No se encontraron instrucciones AGENTS.md en el repositorio descargado. No se aplicaron SQL, cambios de cuentas ni despliegues.
