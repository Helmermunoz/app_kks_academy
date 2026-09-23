# KKs Academy

Prototipo web en Flutter para seguimiento de jugadores de béisbol de todas las posiciones.

## Ejecutar

```sh
flutter pub get
flutter run -d chrome
```

## Estado actual

- Calendario semanal y programa según posición.
- Vista de entrenador de demostración para asignar plantillas.
- Registro temporal de entrenamientos completados.
- Videos locales por día, categoría y autor, reproducción lenta y comentarios con tiempo.
- Diseño con Andrés Muñoz y los pitchers indicados por el propietario.

**Es una demostración:** no hay autenticación, permisos reales ni base de datos. Videos, comentarios y cambios se pierden al recargar. Los archivos de video no se suben a un servidor. El cambio de perfil no ofrece seguridad.

## Continuar: base de datos

1. Elegir proveedor de autenticación, base de datos y almacenamiento privado.
2. Crear cuentas desde administración y flujo de contraseña temporal.
3. Definir alumnos, entrenadores, posiciones principales/secundarias y permisos por alumno.
4. Persistir semanas, sesiones, ejercicios, lanzamientos, distancias y ubicaciones.
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
