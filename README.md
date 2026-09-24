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

## Próximas etapas

1. Crear el proyecto de Supabase y aplicar la configuración incluida.
2. Verificar permisos con las pruebas SQL y cuentas reales de prueba.
3. Incorporar posiciones principales/secundarias por atleta.
4. Ampliar el plan de tiros de texto con ejercicios y cantidades estructuradas.
5. Conservar versiones e historial al modificar posiciones o programas; el prototipo todavía no lo implementa.
6. Incorporar planes de alimentación y asignación de profesionales a las citas de terapia.
7. Agregar comentarios con marca de tiempo, moderación y análisis de movimiento a los videos guardados.
8. Probar aislamiento de datos entre alumnos y permisos del entrenador antes de usar datos reales.

No incluir credenciales ni videos de alumnos en Git. Configurar secretos en el entorno del servidor.

## Comprobaciones

```sh
flutter analyze
flutter test
flutter build web
```
