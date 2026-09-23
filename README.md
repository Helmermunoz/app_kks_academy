# KKs Academy

App web en Flutter para seguimiento de jugadores de béisbol de todas las posiciones.

## Cuentas y entrenamientos personales

La app incluye acceso con Supabase, administrador, entrenadores asignados a atletas,
creación de cuentas con contraseña temporal, entrenamientos privados y registro de
sesiones completadas. Para activar estas funciones, seguir [la guía de configuración](supabase/SETUP.md).
La migración y la función del servidor están incluidas, pero requieren un proyecto
de Supabase configurado y desplegado. Sin configuración se puede explorar la demo.

Los videos compartidos y las métricas de movimiento todavía están pendientes.

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
4. Ampliar los entrenamientos con ejercicios estructurados, lanzamientos, distancias y ubicaciones.
5. Conservar versiones e historial al modificar posiciones o programas; el prototipo todavía no lo implementa.
6. Incorporar planes de alimentación y citas de terapia asignados por profesionales.
7. Subir videos a almacenamiento privado, vinculados al alumno y sesión; persistir comentarios con marca de tiempo y autor.
8. Probar aislamiento de datos entre alumnos y permisos del entrenador antes de usar datos reales.

No incluir credenciales ni videos de alumnos en Git. Configurar secretos en el entorno del servidor.

## Comprobaciones

```sh
flutter analyze
flutter test
flutter build web
```
