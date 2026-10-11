# Propuesta diaria y límite de OpenAI

Migración 008 aplicada al Supabase actual el 11 octubre 2026. Siete suites SQL locales pasaron y la función pasó Deno check. La prueba real con Andrés/Kike aún requiere consentimiento registrado y configuración de servidor.

- Máximo tres reservas de procesamiento por atleta y día de ejecución, en America/Hermosillo. Cuenta fallos, reintentos y modo simulado; no se reinicia al editar ni borrar. Es conservador: una reserva puede agotarse sin que llegue a efectuarse una llamada pagada.
- El registro persistente de reservas y un bloqueo transaccional serializan las peticiones, también las concurrentes. No hay reintentos automáticos dentro de una petición al proveedor. Continúa el límite global de 50 reservas al día.
- Guardar un entrenamiento publicado con cambios materiales crea un trabajo; guardar sin cambios, abrir o recargar no crea otro. Los tres intentos máximos por trabajo siguen vigentes.
- El contexto considera todas las sesiones publicadas del mismo día: títulos, instrucciones, tipo, horario, duración, intensidad y plan de lanzamientos. Un gimnasio escrito como entrenamiento/instrucciones se incluye. No omite terapias ni sesiones con carga desconocida; pide completar datos, sin inventarlos.
- Incluye posición deportiva y preferencias, alergias y restricciones del perfil nutricional. No transmite nombre, ID, fecha de nacimiento, InBody, ubicación, presupuesto ni objetivos clínicos. Se mantiene el bloqueo para menores/nacimiento desconocido y la revisión profesional antes de mostrar el borrador al atleta.
- Un cambio en cualquier actividad del día, su publicación, su fecha o su eliminación invalida el contexto anterior; también un cambio de posición. Los cambios del perfil nutricional invalidan por revisión. Se valida nuevamente antes de guardar y aprobar.
- No se regeneran automáticamente datos históricos al aplicar la migración. Tras consentimiento, modificar y guardar una sesión publicada para crear el trabajo. Los trabajos previos sin firma diaria quedan obsoletos y no se procesan.

Configuración de servidor: NUTRITION_ENABLED=true, NUTRITION_MODE=mock para prueba simulada. Para llamadas reales se necesitan OPENAI_API_KEY, OPENAI_MODEL y NUTRITION_LIVE_APPROVED=true con NUTRITION_MODE=live. Nunca poner secretos en la compilación web. Compilar frontend con ENABLE_NUTRITION_ASSISTANT=true después del despliegue de la función.

Rollback conservador: apagar NUTRITION_ENABLED y recompilar con flag false. Conservar el registro de reservas; no borrarlo ni devolver cupos tras errores ambiguos. Las funciones *_v1 quedan sin permisos de ejecución para clientes y service_role, para impedir saltarse los controles nuevos.
