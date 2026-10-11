# Cuentas iniciales de prueba

El acceso acepta usuario y contraseña. Supabase Auth utiliza internamente un
identificador de correo reservado `USUARIO@users.kksacademy.invalid`; nadie
necesita tener ese buzón. La recuperación la gestiona Helmer. Su acceso por
correo se conserva. No guardar contraseñas en Git ni compartir una entre cuentas.

| Nombre | Usuario | Rol | Posición |
| --- | --- | --- | --- |
| Andrés Muñoz | andres.munoz | athlete | pitcher |
| Enrique Gastelum | enrique.gastelum | athlete | pitcher |
| Brayan Orrantia | brayan.orrantia | athlete | pitcher |
| Alejandro Urías | alejandro.urias | athlete | catcher |
| Abraham Vidaña | abraham.vidana | coach | |
| Miguel Muñoz | miguel.munoz | viewer | |
| Wendy Almodóvar | wendy.almodovar | nutrition | |

Miguel consulta sin permisos de escritura. Wendy consulta y edita nutrición e
InBody de los atletas; no recibe acceso de escritura a entrenamientos ni
acreditación para aprobar propuestas de IA. Abraham necesita asignación a cada
atleta. Las contraseñas elegidas se mantienen hasta que el titular/administrador
solicite cambiarlas; no se exige cambio al primer acceso para estas cuentas.

Aplicar 007 después de 001–006 y desplegar `create-account` actualizado antes de
crear usuarios desde la app. Credenciales nuevas mediante entrada del propietario.
Si se usa Auth Dashboard, crear cada identificador interno con contraseña y
confirmación, después insertar el perfil correspondiente con
`must_change_password=false`, username, rol y posición. Crear perfiles solo para
UUID existentes de Auth; nunca insertar hashes de contraseña por SQL.
