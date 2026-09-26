# Punto de continuación — 26 de septiembre de 2026

El usuario pidió pausar este proyecto para empezar otro.

## Guardado y publicado

- Rama: `main`. Último commit de implementación: `da96155` — `actualizacion de datos: bullpen y seguimiento del entrenador`.
- Ese commit se subió a `origin/main`. Al pausar, no había cambios locales pendientes.
- Web: https://helmermunoz.github.io/app_kks_academy/
- Aplicación Flutter con Supabase: cuentas y roles, entrenamientos privados, terapia, videos comunitarios, nutrición/InBody y tema oscuro.
- Última entrega: resultados de bullpen, panel del entrenador y revisión privada de videos con observación y segundo de referencia.
- Verificación realizada: 20 pruebas Flutter aprobadas, análisis sin problemas y compilación web correcta. Pruebas SQL preparadas, pendientes de ejecutar en un proyecto de prueba.

## Primer paso al retomar

La app pidió aplicar la migración 005. No se ha recibido confirmación de que se haya ejecutado correctamente.

1. Comprobar si ya se ejecutó `supabase/migrations/202609240005_development.sql`.
2. Si no se aplicó, copiar el archivo completo a una consulta nueva en Supabase SQL Editor y ejecutarlo una sola vez. Esperar `Success. No rows returned`.
3. Si hay un error, revisar el mensaje antes de volver a ejecutar; no repetir migraciones anteriores.
4. Recargar la app y probar guardar resultados de bullpen y revisiones con cuentas reales.
5. Comprobar aislamiento entre atletas y pérdida de acceso al retirar la asignación de un entrenador.

Las instrucciones completas están en `supabase/SETUP.md`; las pruebas de permisos están en `supabase/tests/development.sql`.

## Alcance y planes posteriores

- Los conteos y la velocidad son manuales; no hay captura con radar, mapa de lanzamientos ni análisis automático del esqueleto.
- Las revisiones son privadas entre atleta y equipo; los videos continúan disponibles para miembros de la academia.
- Los avisos de molestias aparecen en el panel, sin notificaciones push ni diagnóstico.
- Nutrición/InBody permite guardar datos; la integración con IA sigue pendiente.
- El usuario planea trasladar el alojamiento web de GitHub Pages a Hostinger más adelante. No se ha realizado ese traslado.
- La distribución nativa para iPhone/Android sigue pendiente; actualmente se usa la versión web.

No iniciar nuevos cambios ni despliegues hasta que el usuario retome el proyecto.
