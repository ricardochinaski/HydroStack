# Device provisioning

El flujo definitivo de alta y asociación de dispositivos todavía está pendiente. Este documento registra lo que hace actualmente el código sin presentar la simulación como funcionalidad terminada.

## Comportamiento actual

- La pantalla `ConectarEsp32Screen` muestra una búsqueda por Bluetooth, espera tres segundos con `Future.delayed` y marca el dispositivo como conectado. No existe código Bluetooth ni descubrimiento WiFi detrás de esa pantalla.
- La pantalla permite omitir el paso y continuar al alta de plantas.
- `SettingsState` usa `HS-001` como `deviceId` predeterminado y lo persiste localmente con SharedPreferences.
- La pantalla de simulador/desarrollo permite editar el ID, guardarlo localmente y llamar a `saveDeviceId`.
- Si Firebase está activo, `saveDeviceId` escribe el ID en `usuarios/{uid}`. En modo mock, la operación solo espera brevemente y no vincula hardware.
- Al activar `usarHardware`, la app escucha y escribe bajo `dispositivos/{deviceId}` en RTDB.
- Los firmwares activos también tienen `HS-001` compilado como constante. No existe intercambio verificable de identidad entre app y dispositivo.

## Partes mock o incompletas

- búsqueda y confirmación de conexión en onboarding;
- reinicio de ESP32 desde `Mi Huerta`, que actualmente solo muestra una espera y un mensaje;
- asociación criptográfica entre cuenta y dispositivo;
- entrega de credenciales WiFi/Firebase al hardware;
- comprobación de que el ID ingresado corresponde a un dispositivo presente o autorizado;
- revocación, transferencia y recuperación de dispositivos.

## Decisiones para una fase posterior

- Quién genera el identificador del dispositivo y cómo se evita su suplantación.
- Cómo demuestra el usuario posesión física del equipo.
- Cómo recibe el gateway sus credenciales de red sin incluirlas en el firmware versionado.
- Qué identidad utiliza cada firmware frente a Firebase.
- Cómo se registran ownership, roles, revocación y transferencia.
- Qué mecanismo de transporte se usará para el alta inicial. El repositorio no permite concluir todavía que deba ser Bluetooth o WiFi.
- Cómo separar dispositivos y datos de desarrollo y producción.

No se implementó provisioning en esta reorganización.
