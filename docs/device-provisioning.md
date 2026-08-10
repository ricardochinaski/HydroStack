# Device provisioning

El provisioning físico definitivo todavía está pendiente. Esta fase establece únicamente la base segura de identidad y ownership para evitar que escribir o conocer un `deviceId` equivalga a poseer el dispositivo.

## Identidad, secreto y ownership

Son conceptos distintos:

- **`deviceId`**: identificador técnico único del dispositivo. Puede ser visible y no debe tratarse como secreto.
- **secreto / proof-of-possession**: evidencia que permitirá demostrar posesión física durante un claim futuro. Todavía no está implementada.
- **ownership**: asociación autorizada entre `deviceId` y un UID de Firebase Auth.

La fuente de verdad del ownership es:

`devices/{deviceId}.ownerUid`

El cliente no puede crear ese documento ni cambiar `ownerUid` mediante las reglas de producción versionadas.

## Estado actual implementado

### Dispositivo real

La app usa `DeviceService` y `authorizedDeviceProvider` para resolver el hardware que puede controlar el usuario.

Un ID guardado localmente es solo una preferencia. Antes de usar RTDB, la app exige que Firestore confirme que el documento `devices/{deviceId}` pertenece al UID autenticado.

Si no existe un dispositivo autorizado, la ruta de producción no selecciona automáticamente `HS-001` ni otro ID.

### Modo desarrollo

`SimuladorScreen` conserva una entrada manual de ID exclusivamente para laboratorio.

- está marcada como `MODO DEV MANUAL`;
- el valor se guarda como `developmentDeviceId`;
- `HS-001` sigue siendo el valor legacy de desarrollo para no romper el firmware actual;
- `useDevelopmentDevice` está desactivado por defecto;
- guardar un ID manual no escribe ownership en Firestore;
- la UI ya no afirma que el dispositivo quedó vinculado;
- el modo dev no evita Firebase Security Rules.

### RTDB

Las reglas usan una proyección derivada:

`deviceAccess/{uid}/{deviceId}: true`

El cliente puede leer su propia proyección, pero no escribirla. En una fase futura, el proceso confiable de claim deberá actualizar de forma atómica/coherente:

1. `devices/{deviceId}.ownerUid` en Firestore;
2. la proyección `deviceAccess/{uid}/{deviceId}` en RTDB.

Firestore sigue siendo la fuente de verdad; `deviceAccess` existe únicamente para enforcement de RTDB.

## Compatibilidad legacy

Se conservan temporalmente:

- `usuarios/{uid}.deviceId`;
- `Huerta.esp32Id`;
- `Huerta.esp32Connected`;
- `AppUser.esp32Id`;
- `AppUser.esp32Connected`;
- `DEVICE_ID "HS-001"` en ESP8266 y ESP32-CAM.

No deben usarse como prueba de ownership. La API legacy `saveDeviceId()` ahora valida ownership contra `devices/{deviceId}` antes de guardar la referencia del perfil.

## Onboarding actual

`ConectarEsp32Screen` continúa siendo mock: muestra una búsqueda Bluetooth y finaliza después de una espera, pero no existe BLE ni provisioning WiFi real detrás de esa pantalla. No se cambió en esta fase para evitar mezclar arquitectura de ownership con transporte de provisioning.

## Claim seguro pendiente

No existe todavía un mecanismo que permita crear `devices/{deviceId}` desde la app. Es intencional.

Un claim posterior deberá incluir como mínimo:

1. identidad única emitida para cada unidad;
2. proof-of-possession no derivable únicamente del `deviceId`;
3. usuario Firebase autenticado;
4. operación confiable que asigne `ownerUid`;
5. creación/actualización de la proyección RTDB `deviceAccess`;
6. revocación y transferencia;
7. protección contra replay y claims concurrentes;
8. entrega segura de credenciales de red/hardware.

No se decidió todavía si el transporte inicial será SoftAP/captive portal, BLE, QR u otro mecanismo. Esa decisión pertenece a una fase posterior.

## Resultado de esta fase

Conocer `HS-001` o cualquier otro `deviceId` ya no constituye conceptualmente un claim. La aplicación de producción exige ownership Firestore y las reglas Firebase introducen aislamiento por UID. Lo que falta es el mecanismo confiable que cree esas asociaciones para dispositivos físicos reales.
